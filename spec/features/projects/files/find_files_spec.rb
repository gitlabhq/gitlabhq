require 'spec_helper'

feature 'Find files button in the tree header' do
  given(:user) { create(:user) }
  given(:project) { create(:project) }

  background do
    sign_in(user)
    project.team << [user, :developer]
  end

  scenario 'project main screen' do
    visit project_path(project)

    expect(page).to have_selector('.tree-controls .shortcuts-find-file')
  end

  scenario 'project tree screen' do
    visit project_tree_path(project, project.default_branch)

    expect(page).to have_selector('.tree-controls .shortcuts-find-file')
  end
end
