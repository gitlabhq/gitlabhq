require 'spec_helper'

describe IssuesFinder do
  let(:user) { create :user }
  let(:user2) { create :user }
  let(:project1) { create(:project) }
  let(:project2) { create(:project) }
  let(:milestone) { create(:milestone, project: project1) }
  let(:issue1) { create(:issue, author: user, assignee: user, project: project1, milestone: milestone) }
  let(:issue2) { create(:issue, author: user, assignee: user, project: project2) }
  let(:issue3) { create(:issue, author: user2, assignee: user2, project: project2) }

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
        issues = IssuesFinder.new.execute(user, params)
        issues.size.should == 3
      end

      it 'should filter by assignee id' do
        params = { scope: "all", assignee_id: user.id, state: 'opened' }
        issues = IssuesFinder.new.execute(user, params)
        issues.size.should == 2
      end

      it 'should filter by author id' do
        params = { scope: "all", author_id: user2.id, state: 'opened' }
        issues = IssuesFinder.new.execute(user, params)
        issues.should == [issue3]
      end

      it 'should filter by milestone id' do
        params = { scope: "all", milestone_id: milestone.id, state: 'opened' }
        issues = IssuesFinder.new.execute(user, params)
        issues.should == [issue1]
      end

      it 'should be empty for unauthorized user' do
        params = { scope: "all", state: 'opened' }
        issues = IssuesFinder.new.execute(nil, params)
        issues.size.should be_zero
      end

      it 'should not include unauthorized issues' do
        params = { scope: "all", state: 'opened' }
        issues = IssuesFinder.new.execute(user2, params)
        issues.size.should == 2
        issues.should_not include(issue1)
        issues.should include(issue2)
        issues.should include(issue3)
      end
    end

    context 'personal scope' do
      it 'should filter by assignee' do
        params = { scope: "assigned-to-me", state: 'opened' }
        issues = IssuesFinder.new.execute(user, params)
        issues.size.should == 2
      end

      it 'should filter by project' do
        params = { scope: "assigned-to-me", state: 'opened', project_id: project1.id }
        issues = IssuesFinder.new.execute(user, params)
        issues.size.should == 1
      end
    end
  end
end
