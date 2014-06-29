require 'spec_helper'

describe IssuesFinder do
  let(:user) { create :user }
  let(:user2) { create :user }
  let(:project1) { create(:project) }
  let(:project2) { create(:project) }
  let(:issue1) { create(:issue, assignee: user, project: project1) }
  let(:issue2) { create(:issue, assignee: user, project: project2) }
  let(:issue3) { create(:issue, assignee: user2, project: project2) }

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

    it 'should filter by all' do
      params = { scope: "all", state: 'opened' }
      issues = IssuesFinder.new.execute(user, params)
      expect(issues.size).to eq(3)
    end

    it 'should filter by assignee' do
      params = { scope: "assigned-to-me", state: 'opened' }
      issues = IssuesFinder.new.execute(user, params)
      expect(issues.size).to eq(2)
    end

    it 'should filter by project' do
      params = { scope: "assigned-to-me", state: 'opened', project_id: project1.id }
      issues = IssuesFinder.new.execute(user, params)
      expect(issues.size).to eq(1)
    end

    it 'should be empty for unauthorized user' do
      params = { scope: "all", state: 'opened' }
      issues = IssuesFinder.new.execute(nil, params)
      expect(issues.size).to be_zero
    end

    it 'should not include unauthorized issues' do
      params = { scope: "all", state: 'opened' }
      issues = IssuesFinder.new.execute(user2, params)
      expect(issues.size).to eq(2)
      expect(issues).not_to include(issue1)
      expect(issues).to include(issue2)
      expect(issues).to include(issue3)
    end
  end
end
