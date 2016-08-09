require 'rails_helper'

feature 'Manually create a todo item from issue', feature: true, js: true do
  let!(:project)   { create(:project) }
  let!(:issue)     { create(:issue, project: project) }
  let!(:user)      { create(:user)}

  before do
    project.team << [user, :master]
    login_as(user)
    visit namespace_project_issue_path(project.namespace, project, issue)
  end

  it 'creates todo when clicking button' do
    page.within '.issuable-sidebar' do
      click_button 'Add Todo'
      expect(page).to have_content 'Mark Done'
    end

    page.within '.header-content .todos-pending-count' do
      expect(page).to have_content '1'
    end

    visit namespace_project_issue_path(project.namespace, project, issue)

    page.within '.header-content .todos-pending-count' do
      expect(page).to have_content '1'
    end
  end

  it 'marks a todo as done' do
    page.within '.issuable-sidebar' do
      click_button 'Add Todo'
      click_button 'Mark Done'
    end

    expect(page).to have_selector('.todos-pending-count', visible: false)

    visit namespace_project_issue_path(project.namespace, project, issue)

    expect(page).to have_selector('.todos-pending-count', visible: false)
  end
end
