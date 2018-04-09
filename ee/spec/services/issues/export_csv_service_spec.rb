require 'spec_helper'

describe Issues::ExportCsvService do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let!(:issue)  { create(:issue, project: project, author: user) }
  let!(:bad_issue) { create(:issue, project: project, author: user) }
  let(:subject) { described_class.new(Issue.all) }

  it 'renders csv to string' do
    expect(subject.csv_data).to be_a String
  end

  describe '#email' do
    it 'emails csv' do
      expect { subject.email(user, project) }.to change(ActionMailer::Base.deliveries, :count)
    end

    it 'renders with a target filesize' do
      expect(subject.csv_builder).to receive(:render).with(described_class::TARGET_FILESIZE)

      subject.email(user, project)
    end
  end

  def csv
    CSV.parse(subject.csv_data, headers: true)
  end

  context 'includes' do
    let(:milestone) { create(:milestone, title: 'v1.0', project: project) }
    let(:idea_label) { create(:label, project: project, title: 'Idea') }
    let(:feature_label) { create(:label, project: project, title: 'Feature') }

    before do
      issue.update!(milestone: milestone,
                    assignees: [user],
                    description: 'Issue with details',
                    state: :opened,
                    due_date: DateTime.new(2014, 3, 2),
                    created_at: DateTime.new(2015, 4, 3, 2, 1, 0),
                    updated_at: DateTime.new(2016, 5, 4, 3, 2, 1),
                    closed_at: DateTime.new(2017, 6, 5, 4, 3, 2),
                    weight: 4,
                    discussion_locked: true,
                    labels: [feature_label, idea_label],
                    time_estimate: 72000)
      issue.timelogs.create(time_spent: 360, user: user)
      issue.timelogs.create(time_spent: 200, user: user)
    end

    specify 'iid' do
      expect(csv[0]['Issue ID']).to eq issue.iid.to_s
    end

    specify 'url' do
      expect(csv[0]['URL']).to match(/http.*#{project.full_path}.*#{issue.iid}/)
    end

    specify 'title' do
      expect(csv[0]['Title']).to eq issue.title
    end

    specify 'state' do
      expect(csv[0]['State']).to eq 'Open'
    end

    specify 'description' do
      expect(csv[0]['Description']).to eq issue.description
      expect(csv[1]['Description']).to eq nil
    end

    specify 'author name' do
      expect(csv[0]['Author']).to eq issue.author_name
    end

    specify 'author username' do
      expect(csv[0]['Author Username']).to eq issue.author.username
    end

    specify 'assignee name' do
      expect(csv[0]['Assignee']).to eq user.name
      expect(csv[1]['Assignee']).to eq ''
    end

    specify 'assignee username' do
      expect(csv[0]['Assignee Username']).to eq user.username
      expect(csv[1]['Assignee Username']).to eq ''
    end

    specify 'confidential' do
      expect(csv[0]['Confidential']).to eq 'No'
    end

    specify 'milestone' do
      expect(csv[0]['Milestone']).to eq issue.milestone.title
      expect(csv[1]['Milestone']).to eq nil
    end

    specify 'labels' do
      expect(csv[0]['Labels']).to eq 'Feature,Idea'
      expect(csv[1]['Labels']).to eq nil
    end

    specify 'due_date' do
      expect(csv[0]['Due Date']).to eq '2014-03-02'
      expect(csv[1]['Due Date']).to eq nil
    end

    specify 'created_at' do
      expect(csv[0]['Created At (UTC)']).to eq '2015-04-03 02:01:00'
    end

    specify 'updated_at' do
      expect(csv[0]['Updated At (UTC)']).to eq '2016-05-04 03:02:01'
    end

    specify 'closed_at' do
      expect(csv[0]['Closed At (UTC)']).to eq '2017-06-05 04:03:02'
      expect(csv[1]['Closed At (UTC)']).to eq nil
    end

    specify 'discussion_locked' do
      expect(csv[0]['Locked']).to eq 'Yes'
    end

    specify 'weight' do
      expect(csv[0]['Weight']).to eq '4'
    end

    specify 'time estimate' do
      expect(csv[0]['Time Estimate']).to eq '72000'
      expect(csv[1]['Time Estimate']).to eq '0'
    end

    specify 'time spent' do
      expect(csv[0]['Time Spent']).to eq '560'
      expect(csv[1]['Time Spent']).to eq '0'
    end

    context 'with issues filtered by labels and project' do
      let(:subject) do
        described_class.new(
          IssuesFinder.new(user,
                           project_id: project.id,
                           label_name: %w(Idea Feature)).execute)
      end

      it 'returns only filtered objects' do
        expect(csv.count).to eq(1)
        expect(csv[0]['Issue ID']).to eq issue.iid.to_s
      end
    end
  end

  context 'with minimal details' do
    it 'renders labels as nil' do
      expect(csv[0]['Labels']).to eq nil
    end
  end
end
