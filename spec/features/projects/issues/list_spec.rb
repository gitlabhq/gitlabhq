require 'spec_helper'

feature 'Issues List' do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }

  background do
    project.team << [user, :developer]

    login_as(user)
  end

  scenario 'user does not see create new list button' do
    create(:issue, project: project)

    visit namespace_project_issues_path(project.namespace, project)

    expect(page).not_to have_selector('.js-new-board-list')
  end
end
