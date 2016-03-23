require 'rails_helper'

feature 'Multiple issue updating from issues#index', feature: true do
  let!(:project)   { create(:project) }
  let!(:issue)     { create(:issue, project: project) }
  let!(:user)      { create(:user)}

  context 'status update', js: true do
    before do
      project.team << [user, :master]
      login_as(user)
    end

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

  def create_closed
    create(:issue, project: project, state: :closed)
  end

  def click_update_issues_button
    find('.update_selected_issues').click
  end
end
