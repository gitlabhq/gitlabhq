require 'rails_helper'

feature 'Multiple issue updating from issues#index', feature: true do
  let!(:project)   { create(:project) }
  let!(:issue)     { create(:issue, project: project) }
  let!(:user)      { create(:user)}

  before do
    project.team << [user, :master]
    login_as(user)
  end

  context 'status', js: true do
    it 'should be set to closed' do
      visit namespace_project_issues_path(project.namespace, project)

      find('#check_all_issues').click
      find('.js-issue-status').click

      find('.dropdown-menu-status a', text: 'Closed').click
      click_update_issues_button
      expect(page).to have_selector('.issue', count: 0)
    end

    it 'should be set to open' do
      create_closed
      visit namespace_project_issues_path(project.namespace, project)

      find('.issues-state-filters a', text: 'Closed').click

      find('#check_all_issues').click
      find('.js-issue-status').click

      find('.dropdown-menu-status a', text: 'Open').click
      click_update_issues_button
      expect(page).to have_selector('.issue', count: 0)
    end
  end

  context 'assignee', js: true do
    it 'should update to current user' do
      visit namespace_project_issues_path(project.namespace, project)

      find('#check_all_issues').click
      find('.js-update-assignee').click

      find('.dropdown-menu-user-link', text: user.username).click
      click_update_issues_button

      page.within('.issue .controls') do
        expect(find('.author_link')["title"]).to have_content(user.name)
      end
    end

    it 'should update to unassigned' do
      create_assigned
      visit namespace_project_issues_path(project.namespace, project)

      find('#check_all_issues').click
      find('.js-update-assignee').click

      click_link 'Unassigned'
      click_update_issues_button

      within first('.issue .controls') do
        expect(page).to have_no_selector('.author_link')
      end
    end
  end

  context 'milestone', js: true do
    let(:milestone)  { create(:milestone, project: project) }

    it 'should update milestone' do
      visit namespace_project_issues_path(project.namespace, project)

      find('#check_all_issues').click
      find('.issues_bulk_update .js-milestone-select').click

      find('.dropdown-menu-milestone a', text: milestone.title).click
      click_update_issues_button

      expect(find('.issue')).to have_content milestone.title
    end

    it 'should set to no milestone' do
      create_with_milestone
      visit namespace_project_issues_path(project.namespace, project)

      expect(first('.issue')).to have_content milestone.title

      find('#check_all_issues').click
      find('.issues_bulk_update .js-milestone-select').click

      find('.dropdown-menu-milestone a', text: "No Milestone").click
      click_update_issues_button

      expect(first('.issue')).to_not have_content milestone.title
    end
  end

  def create_closed
    create(:issue, project: project, state: :closed)
  end

  def create_assigned
    create(:issue, project: project, assignee: user)
  end

  def create_with_milestone
    create(:issue, project: project, milestone: milestone)
  end

  def click_update_issues_button
    find('.update_selected_issues').click
  end
end
