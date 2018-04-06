require 'spec_helper'

describe Burndown do
  let(:start_date) { "2017-03-01" }
  let(:due_date)   { "2017-03-05" }
  let(:milestone)  { create(:milestone, start_date: start_date, due_date: due_date) }
  let(:project)    { milestone.project }
  let(:user)       { create(:user) }

  let(:issue_params) do
    {
      title: FFaker::Lorem.sentence(6),
      description: FFaker::Lorem.sentence,
      state: 'opened',
      milestone: milestone,
      weight: 2,
      project_id: project.id
    }
  end

  around do |example|
    Timecop.travel(due_date) do
      example.run
    end
  end

  before do
    project.add_master(user)
    build_sample
  end

  subject { described_class.new(milestone).to_json }

  it "generates an array with date, issue count and weight" do
    expect(subject).to eq([
      ["2017-03-01", 33, 66],
      ["2017-03-02", 35, 70],
      ["2017-03-03", 28, 56],
      ["2017-03-04", 32, 64],
      ["2017-03-05", 21, 42]
    ].to_json)
  end

  it "returns empty array if milestone start date is nil" do
    milestone.update(start_date: nil)

    expect(subject).to eq([].to_json)
  end

  it "returns empty array if milestone due date is nil" do
    milestone.update(due_date: nil)

    expect(subject).to eq([].to_json)
  end

  it "it counts until today if milestone due date > Date.today" do
    Timecop.travel(milestone.due_date - 1.day) do
      expect(JSON.parse(subject).last[0]).to eq(Time.now.strftime("%Y-%m-%d"))
    end
  end

  it "sets attribute accurate to true" do
    burndown = described_class.new(milestone)

    expect(burndown).to be_accurate
  end

  context "when all closed issues does not have closed events" do
    before do
      Event.where(target: milestone.issues, action: Event::CLOSED).destroy_all
    end

    it "considers closed_at as milestone start date" do
      expect(subject).to eq([
        ["2017-03-01", 27, 54],
        ["2017-03-02", 27, 54],
        ["2017-03-03", 27, 54],
        ["2017-03-04", 27, 54],
        ["2017-03-05", 27, 54]
      ].to_json)
    end

    it "sets attribute empty to true" do
      burndown = described_class.new(milestone)

      expect(burndown).to be_empty
    end
  end

  context "when one or more closed issues does not have a closed event" do
    before do
      Event.where(target: milestone.issues.closed.first, action: Event::CLOSED).destroy_all
    end

    it "sets attribute accurate to false" do
      burndown = described_class.new(milestone)

      expect(burndown).not_to be_accurate
    end
  end

  # Creates, closes and reopens issues only for odd days numbers
  def build_sample
    milestone.start_date.upto(milestone.due_date) do |date|
      day = date.day
      next if day.even?

      count = day * 4
      Timecop.travel(date) do
        # Create issues
        issues = create_list(:issue, count, issue_params)

        # Close issues
        closed = issues.slice(0..count / 2)
        closed.each { |issue| close_issue(issue) }

        # Reopen issues
        reopened_issues = closed.slice(0..count / 4)
        reopened_issues.each { |issue| reopen_issue(issue) }

        # This generates an issue with multiple closing events
        issue_closed_twice = reopened_issues.last
        close_issue(issue_closed_twice)
        reopen_issue(issue_closed_twice)
      end
    end
  end

  def close_issue(issue)
    Issues::CloseService.new(issue.project, user, {}).execute(issue)
  end

  def reopen_issue(issue)
    Issues::ReopenService.new(issue.project, user, {}).execute(issue)
  end
end
