# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Manually create a todo item from issue', :js, feature_category: :notifications do
  let!(:project) { create(:project) }
  let!(:issue)   { create(:issue, project: project) }
  let!(:user)    { create(:user) }

  before do
    stub_feature_flags(notifications_todos_buttons: false)
    stub_feature_flags(work_item_view_for_issues: true)
    project.add_maintainer(user)
    sign_in(user)
    visit project_issue_path(project, issue)
  end

  it 'creates todo when clicking button' do
    click_button 'Add a to-do item'

    expect(page).to have_button 'Mark as done'
    expect(page).to have_link 'To-do items'
  end

  it 'marks a todo as done' do
    click_button 'Add a to-do item'
    click_button 'Mark as done'

    expect(page).to have_link 'To-do items'
  end
end
