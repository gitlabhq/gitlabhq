require 'spec_helper'

feature 'Issues List' do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }

  background do
    project.team << [user, :developer]

    gitlab_sign_in(user)
  end

  scenario 'user does not see create new list button' do
    create(:issue, project: project)

    visit namespace_project_issues_path(project.namespace, project)

    expect(page).not_to have_selector('.js-new-board-list')
  end

  scenario 'user seems an empty state' do
    visit namespace_project_issues_path(project.namespace, project)

    expect(page).to have_selector('.empty-state')
  end
end
