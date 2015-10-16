require 'spec_helper'

describe IssuesFinder do
  let(:user) { create :user }
  let(:user2) { create :user }
  let(:project1) { create(:project) }
  let(:project2) { create(:project) }
  let(:milestone) { create(:milestone, project: project1) }
  let(:label) { create(:label, project: project2) }
  let(:issue1) { create(:issue, author: user, assignee: user, project: project1, milestone: milestone) }
  let(:issue2) { create(:issue, author: user, assignee: user, project: project2) }
  let(:issue3) { create(:issue, author: user2, assignee: user2, project: project2) }
  let!(:label_link) { create(:label_link, label: label, target: issue2) }

  before do
    project1.team << [user, :master]
    project2.team << [user, :developer]
    project2.team << [user2, :developer]
  end

  describe :execute do
    before :each do
      issue1
      issue2
      issue3
    end

    context 'scope: all' do
      it 'should filter by all' do
        params = { scope: "all", state: 'opened' }
        issues = IssuesFinder.new(user, params).execute
        expect(issues.size).to eq(3)
      end

      it 'should filter by assignee id' do
        params = { scope: "all", assignee_id: user.id, state: 'opened' }
        issues = IssuesFinder.new(user, params).execute
        expect(issues.size).to eq(2)
      end

      it 'should filter by author id' do
        params = { scope: "all", author_id: user2.id, state: 'opened' }
        issues = IssuesFinder.new(user, params).execute
        expect(issues).to eq([issue3])
      end

      it 'should filter by milestone id' do
        params = { scope: "all", milestone_title: milestone.title, state: 'opened' }
        issues = IssuesFinder.new(user, params).execute
        expect(issues).to eq([issue1])
      end

      it 'should filter by no milestone id' do
        params = { scope: "all", milestone_title: Milestone::None.title, state: 'opened' }
        issues = IssuesFinder.new(user, params).execute
        expect(issues).to match_array([issue2, issue3])
      end

      it 'should filter by label name' do
        params = { scope: "all", label_name: label.title, state: 'opened' }
        issues = IssuesFinder.new(user, params).execute
        expect(issues).to eq([issue2])
      end

      it 'should filter by no label name' do
        params = { scope: "all", label_name: Label::None.title, state: 'opened' }
        issues = IssuesFinder.new(user, params).execute
        expect(issues).to match_array([issue1, issue3])
      end

      it 'should be empty for unauthorized user' do
        params = { scope: "all", state: 'opened' }
        issues = IssuesFinder.new(nil, params).execute
        expect(issues.size).to be_zero
      end

      it 'should not include unauthorized issues' do
        params = { scope: "all", state: 'opened' }
        issues = IssuesFinder.new(user2, params).execute
        expect(issues.size).to eq(2)
        expect(issues).not_to include(issue1)
        expect(issues).to include(issue2)
        expect(issues).to include(issue3)
      end
    end

    context 'personal scope' do
      it 'should filter by assignee' do
        params = { scope: "assigned-to-me", state: 'opened' }
        issues = IssuesFinder.new(user, params).execute
        expect(issues.size).to eq(2)
      end

      it 'should filter by project' do
        params = { scope: "assigned-to-me", state: 'opened', project_id: project1.id }
        issues = IssuesFinder.new(user, params).execute
        expect(issues.size).to eq(1)
      end
    end
  end
end
