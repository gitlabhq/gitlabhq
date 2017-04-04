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
      click_button 'Add todo'
      expect(page).to have_content 'Mark done'
    end

    page.within '.header-content .todos-count' do
      expect(page).to have_content '1'
    end

    visit namespace_project_issue_path(project.namespace, project, issue)

    page.within '.header-content .todos-count' do
      expect(page).to have_content '1'
    end
  end

  it 'marks a todo as done' do
    page.within '.issuable-sidebar' do
      click_button 'Add todo'
      click_button 'Mark done'
    end

    expect(page).to have_selector('.todos-count', visible: false)

    visit namespace_project_issue_path(project.namespace, project, issue)

    expect(page).to have_selector('.todos-count', visible: false)
  end
end
