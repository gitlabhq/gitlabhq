require 'spec_helper'

describe FilterContext do

  let(:user) { create :user }
  let(:user2) { create :user }
  let(:project1) { create(:project, creator_id: user.id) }
  let(:project2) { create(:project, creator_id: user.id) }
  let(:merge_request1) { create(:merge_request, author_id: user.id, source_project: project1, target_project: project2) }
  let(:merge_request2) { create(:merge_request, author_id: user.id, source_project: project2, target_project: project1) }
  let(:merge_request3) { create(:merge_request, author_id: user.id, source_project: project2, target_project: project2) }
  let(:merge_request4) { create(:merge_request, author_id: user2.id, source_project: project2, target_project: project2, target_branch:"notes_refactoring") }
  let(:issue1) { create(:issue, assignee_id: user.id, project: project1) }
  let(:issue2) { create(:issue, assignee_id: user.id, project: project2) }
  let(:issue3) { create(:issue, assignee_id: user2.id, project: project2) }

  describe 'merge requests' do
    before :each do
      merge_request1
      merge_request2
      merge_request3
      merge_request4
    end

    it 'should by default filter properly' do
      merge_requests = user.cared_merge_requests
      params ={}
      merge_requests = FilterContext.new(merge_requests, params).execute
      merge_requests.size.should == 3
    end

    it 'should apply blocks passed in on creation to the filters' do
      merge_requests = user.cared_merge_requests
      params = {:project_id => project1.id}
      merge_requests = FilterContext.new(merge_requests, params).execute
      merge_requests.size.should == 1
    end
  end

  describe 'issues' do
    before :each do
      issue1
      issue2
      issue3
    end
    it 'should by default filter projects properly' do
      issues = user.assigned_issues
      params = {}
      issues = FilterContext.new(issues, params).execute
      issues.size.should == 2
    end
    it 'should apply blocks passed in on creation to the filters' do
      issues = user.assigned_issues
      params = {:project_id => project1.id}
      issues = FilterContext.new(issues, params).execute
      issues.size.should == 1
    end
  end
end
