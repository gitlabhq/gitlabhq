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
end
