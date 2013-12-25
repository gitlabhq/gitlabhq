require 'spec_helper'

describe FilterContext do
  let(:user) { create :user }
  let(:user2) { create :user }
  let(:project1) { create(:project) }
  let(:project2) { create(:project) }
  let(:merge_request1) { create(:merge_request, author: user, source_project: project1, target_project: project2) }
  let(:merge_request2) { create(:merge_request, author: user, source_project: project2, target_project: project1) }
  let(:merge_request3) { create(:merge_request, author: user, source_project: project2, target_project: project2) }
  let(:issue1) { create(:issue, assignee: user, project: project1) }
  let(:issue2) { create(:issue, assignee: user, project: project2) }
  let(:issue3) { create(:issue, assignee: user2, project: project2) }

  before do
    project1.team << [user, :master]
    project2.team << [user, :developer]
  end

  describe 'merge requests' do
    before :each do
      merge_request1
      merge_request2
      merge_request3
    end

    it 'should filter by scope' do
      params = { scope: 'authored' }
      merge_requests = FilterContext.new(MergeRequest, user, params).execute
      merge_requests.size.should == 3
    end

    it 'should filter by project' do
      params = { project_id: project1.id, scope: 'authored' }
      merge_requests = FilterContext.new(MergeRequest, user, params).execute
      merge_requests.size.should == 1
    end
  end

  describe 'issues' do
    before :each do
      issue1
      issue2
      issue3
    end

    it 'should filter by all' do
      params = { scope: "all" }
      issues = FilterContext.new(Issue, user, params).execute
      issues.size.should == 3
    end

    it 'should filter by assignee' do
      params = {}
      issues = FilterContext.new(Issue, user, params).execute
      issues.size.should == 2
    end

    it 'should filter by project' do
      params = { project_id: project1.id }
      issues = FilterContext.new(Issue, user, params).execute
      issues.size.should == 1
    end
  end
end
