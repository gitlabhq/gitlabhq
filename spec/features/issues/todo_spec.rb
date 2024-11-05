# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Manually create a todo item from issue', :js, feature_category: :notifications do
  let!(:project) { create(:project) }
  let!(:issue)   { create(:issue, project: project) }
  let!(:user)    { create(:user) }

  before do
    stub_feature_flags(notifications_todos_buttons: false)
    project.add_maintainer(user)
    sign_in(user)
    visit project_issue_path(project, issue)
  end

  it 'creates todo when clicking button' do
    page.within '.issuable-sidebar' do
      click_button 'Add a to-do item'
      expect(page).to have_content 'Mark as done'
    end

    within_testid 'todos-shortcut-button' do
      expect(page).to have_content '1'
    end

    visit project_issue_path(project, issue)

    within_testid 'todos-shortcut-button' do
      expect(page).to have_content '1'
    end
  end

  it 'marks a todo as done' do
    page.within '.issuable-sidebar' do
      click_button 'Add a to-do item'
      click_button 'Mark as done'
    end

    expect(page).to have_selector("[data-testid='todos-shortcut-button']", text: '')

    visit project_issue_path(project, issue)

    expect(page).to have_selector("[data-testid='todos-shortcut-button']", text: '')
  end
end
