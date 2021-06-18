# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Multiple issue updating from issues#index', :js do
  let!(:project)   { create(:project) }
  let!(:issue)     { create(:issue, project: project) }
  let!(:user)      { create(:user)}

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'status' do
    it 'sets to closed', :js do
      visit project_issues_path(project)

      click_button 'Edit issues'
      check 'Select all'
      click_button 'Select status'
      click_button 'Closed'

      click_update_issues_button
      expect(page).to have_selector('.issue', count: 0)
    end

    it 'sets to open', :js do
      create_closed
      visit project_issues_path(project, state: 'closed')

      click_button 'Edit issues'
      check 'Select all'
      click_button 'Select status'
      click_button 'Open'

      click_update_issues_button
      expect(page).to have_selector('.issue', count: 0)
    end
  end

  context 'assignee' do
    it 'updates to current user' do
      visit project_issues_path(project)

      click_button 'Edit issues'
      check 'Select all'
      click_update_assignee_button
      click_link user.username

      click_update_issues_button

      page.within('.issue .controls') do
        expect(find('.author-link')['href']).to have_content(user.website_url)
      end
    end

    it 'updates to unassigned' do
      create_assigned
      visit project_issues_path(project)

      expect(find('.issue:first-of-type')).to have_link "Assigned to #{user.name}"

      click_button 'Edit issues'
      check 'Select all'
      click_update_assignee_button
      click_link 'Unassigned'
      click_update_issues_button

      expect(find('.issue:first-of-type')).not_to have_link "Assigned to #{user.name}"
    end
  end

  context 'milestone' do
    let!(:milestone) { create(:milestone, project: project) }

    it 'updates milestone' do
      visit project_issues_path(project)

      click_button 'Edit issues'
      check 'Select all'
      click_button 'Select milestone'
      click_link milestone.title
      click_update_issues_button

      expect(page.find('.issue')).to have_content milestone.title
    end

    it 'sets to no milestone' do
      create_with_milestone
      visit project_issues_path(project)

      wait_for_requests

      expect(find('.issue:first-of-type')).to have_text milestone.title

      click_button 'Edit issues'
      check 'Select all'
      click_button 'Select milestone'
      click_link 'No milestone'
      click_update_issues_button

      expect(find('.issue:first-of-type')).not_to have_text milestone.title
    end
  end

  def create_closed
    create(:issue, project: project, state: :closed)
  end

  def create_assigned
    create(:issue, project: project, assignees: [user])
  end

  def create_with_milestone
    create(:issue, project: project, milestone: milestone)
  end

  def click_update_assignee_button
    click_button 'Select assignee'
    wait_for_requests
  end

  def click_update_issues_button
    click_button 'Update all'
    wait_for_requests
  end
end
