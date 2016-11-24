require 'spec_helper'

feature 'user checks git blame', feature: true do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.team << [user, :master]
    login_with(user)
    visit namespace_project_tree_path(project.namespace, project, project.default_branch)
  end

  scenario "can see blame of '.gitignore'" do
    click_link ".gitignore"
    click_link 'Blame'
    
    expect(page).to have_content "*.rb"
    expect(page).to have_content "Dmitriy Zaporozhets"
    expect(page).to have_content "Initial commit"
  end
end
