require 'spec_helper'

feature 'Merge Requests List' do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  background do
    project.team << [user, :developer]

    login_as(user)
  end

  scenario 'user does not see create new list button' do
    create(:merge_request, source_project: project)

    visit namespace_project_merge_requests_path(project.namespace, project)

    expect(page).not_to have_selector('.js-new-board-list')
  end

  it 'should show an empty state' do
    visit namespace_project_merge_requests_path(project.namespace, project)

    expect(page).to have_selector('.empty-state')
  end

  it 'empty state should have a create merge request button' do
    visit namespace_project_merge_requests_path(project.namespace, project)

    expect(page).to have_link 'New merge request', href: new_namespace_project_merge_request_path(project.namespace, project)
  end

  context 'if there are merge requests' do
    before do
      create(:merge_request, assignee: user, source_project: project)

      visit namespace_project_merge_requests_path(project.namespace, project)
    end

    it 'should not show an empty state' do
      expect(page).not_to have_selector('.empty-state')
    end
  end
end
