require 'rails_helper'

feature 'Manually create a todo item from issue', :js do
  let!(:project) { create(:project) }
  let!(:issue)   { create(:issue, project: project) }
  let!(:user)    { create(:user)}

  before do
    project.add_master(user)
    sign_in(user)
    visit project_issue_path(project, issue)
  end

  it 'creates todo when clicking button' do
    page.within '.issuable-sidebar' do
      click_button 'Add todo'
      expect(page).to have_content 'Mark todo as done'
    end

    page.within '.header-content .todos-count' do
      expect(page).to have_content '1'
    end

    visit project_issue_path(project, issue)

    page.within '.header-content .todos-count' do
      expect(page).to have_content '1'
    end
  end

  it 'marks a todo as done' do
    page.within '.issuable-sidebar' do
      click_button 'Add todo'
      click_button 'Mark todo as done'
    end

    expect(page).to have_selector('.todos-count', visible: false)

    visit project_issue_path(project, issue)

    expect(page).to have_selector('.todos-count', visible: false)
  end
end
