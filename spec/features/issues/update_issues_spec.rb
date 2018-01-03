require 'rails_helper'

feature 'Multiple issue updating from issues#index', :js do
  let!(:project)   { create(:project) }
  let!(:issue)     { create(:issue, project: project) }
  let!(:user)      { create(:user)}

  before do
    project.add_master(user)
    sign_in(user)
  end

  context 'status' do
    it 'sets to closed' do
      visit project_issues_path(project)

      click_button 'Edit issues'
      find('#check-all-issues').click
      find('.js-issue-status').click

      find('.dropdown-menu-status a', text: 'Closed').click
      click_update_issues_button
      expect(page).to have_selector('.issue', count: 0)
    end

    it 'sets to open' do
      create_closed
      visit project_issues_path(project, state: 'closed')

      click_button 'Edit issues'
      find('#check-all-issues').click
      find('.js-issue-status').click

      find('.dropdown-menu-status a', text: 'Open').click
      click_update_issues_button
      expect(page).to have_selector('.issue', count: 0)
    end
  end

  context 'assignee' do
    it 'updates to current user' do
      visit project_issues_path(project)

      click_button 'Edit issues'
      find('#check-all-issues').click
      click_update_assignee_button

      find('.dropdown-menu-user-link', text: user.username).click
      click_update_issues_button

      page.within('.issue .controls') do
        expect(find('.author_link')["title"]).to have_content(user.name)
      end
    end

    it 'updates to unassigned' do
      create_assigned
      visit project_issues_path(project)

      click_button 'Edit issues'
      find('#check-all-issues').click
      click_update_assignee_button

      click_link 'Unassigned'
      click_update_issues_button
      expect(find('.issue:first-child .controls')).not_to have_css('.author_link')
    end
  end

  context 'milestone' do
    let!(:milestone) { create(:milestone, project: project) }

    it 'updates milestone' do
      visit project_issues_path(project)

      click_button 'Edit issues'
      find('#check-all-issues').click
      find('.issues-bulk-update .js-milestone-select').click

      find('.dropdown-menu-milestone a', text: milestone.title).click
      click_update_issues_button

      expect(find('.issue')).to have_content milestone.title
    end

    it 'sets to no milestone' do
      create_with_milestone
      visit project_issues_path(project)

      expect(first('.issue')).to have_content milestone.title

      click_button 'Edit issues'
      find('#check-all-issues').click
      find('.issues-bulk-update .js-milestone-select').click

      find('.dropdown-menu-milestone a', text: "No Milestone").click
      click_update_issues_button

      expect(find('.issue:first-child')).not_to have_content milestone.title
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
    find('.js-update-assignee').click
    wait_for_requests
  end

  def click_update_issues_button
    find('.update-selected-issues').click
    wait_for_requests
  end
end
