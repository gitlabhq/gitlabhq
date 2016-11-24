require 'rails_helper'

describe 'Milestone draggable', feature: true, js: true do
  let(:milestone) { create(:milestone, project: project, title: 8.14) }
  let(:project)   { create(:empty_project, :public) }
  let(:user)      { create(:user) }

  context 'issues' do
    let(:issue)        { page.find_by_id('issues-list-unassigned').find('li') }
    let(:issue_target) { page.find_by_id('issues-list-ongoing') }

    it 'does not allow guest to drag issue' do
      create_and_drag_issue

      expect(issue_target).not_to have_selector('.issuable-row')
    end

    it 'does not allow authorized user to drag issue' do
      login_as(user)
      create_and_drag_issue

      expect(issue_target).not_to have_selector('.issuable-row')
    end

    it 'allows author to drag issue' do
      login_as(user)
      create_and_drag_issue(author: user)

      expect(issue_target).to have_selector('.issuable-row')
    end

    it 'allows admin to drag issue' do
      login_as(:admin)
      create_and_drag_issue

      expect(issue_target).to have_selector('.issuable-row')
    end
  end

  context 'merge requests' do
    let(:merge_request)        { page.find_by_id('merge_requests-list-unassigned').find('li') }
    let(:merge_request_target) { page.find_by_id('merge_requests-list-ongoing') }

    it 'does not allow guest to drag merge request' do
      create_and_drag_merge_request

      expect(merge_request_target).not_to have_selector('.issuable-row')
    end

    it 'does not allow authorized user to drag merge request' do
      login_as(user)
      create_and_drag_merge_request

      expect(merge_request_target).not_to have_selector('.issuable-row')
    end

    it 'allows author to drag merge request' do
      login_as(user)
      create_and_drag_merge_request(author: user)

      expect(merge_request_target).to have_selector('.issuable-row')
    end

    it 'allows admin to drag merge request' do
      login_as(:admin)
      create_and_drag_merge_request

      expect(merge_request_target).to have_selector('.issuable-row')
    end
  end

  def create_and_drag_issue(params = {})
    create(:issue, params.merge(title: 'Foo', project: project, milestone: milestone))

    visit namespace_project_milestone_path(project.namespace, project, milestone)
    issue.drag_to(issue_target)
  end

  def create_and_drag_merge_request(params = {})
    create(:merge_request, params.merge(title: 'Foo', source_project: project, target_project: project, milestone: milestone))

    visit namespace_project_milestone_path(project.namespace, project, milestone)
    page.find("a[href='#tab-merge-requests']").click
    merge_request.drag_to(merge_request_target)
  end
end
