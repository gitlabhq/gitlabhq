require 'rails_helper'

feature 'Multiple merge requests updating from merge_requests#index', feature: true do
  include WaitForAjax

  let!(:user)    { create(:user)}
  let!(:project) { create(:project) }
  let!(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  before do
    project.team << [user, :master]
    login_as(user)
  end

  context 'status', js: true do
    it 'sets to closed' do
      visit namespace_project_merge_requests_path(project.namespace, project)

      find('#check_all_issues').click
      find('.js-issue-status').click

      find('.dropdown-menu-status a', text: 'Closed').click
      click_update_merge_requests_button
      expect(page).to have_selector('.merge-request', count: 0)
    end

    it 'sets to open' do
      merge_request.close
      visit namespace_project_merge_requests_path(project.namespace, project, state: 'closed')

      find('#check_all_issues').click
      find('.js-issue-status').click

      find('.dropdown-menu-status a', text: 'Open').click
      click_update_merge_requests_button
      expect(page).to have_selector('.merge-request', count: 0)
    end
  end

  context 'assignee', js: true do
    it 'updates to current user' do
      visit namespace_project_merge_requests_path(project.namespace, project)

      find('#check_all_issues').click
      click_update_assignee_button

      find('.dropdown-menu-user-link', text: user.username).click
      click_update_merge_requests_button

      page.within('.merge-request .controls') do
        expect(find('.author_link')["title"]).to have_content(user.name)
      end
    end

    it 'updates to unassigned' do
      merge_request.assignee = user
      merge_request.save
      visit namespace_project_merge_requests_path(project.namespace, project)

      find('#check_all_issues').click
      click_update_assignee_button

      click_link 'Unassigned'
      click_update_merge_requests_button
      expect(find('.merge-request:first-child .controls')).not_to have_css('.author_link')
    end
  end

  context 'milestone', js: true do
    let(:milestone)  { create(:milestone, project: project) }

    it 'updates milestone' do
      visit namespace_project_merge_requests_path(project.namespace, project)

      find('#check_all_issues').click
      find('.issues_bulk_update .js-milestone-select').click

      find('.dropdown-menu-milestone a', text: milestone.title).click
      click_update_merge_requests_button

      expect(find('.merge-request')).to have_content milestone.title
    end

    it 'sets to no milestone' do
      merge_request.milestone = milestone
      merge_request.save

      visit namespace_project_merge_requests_path(project.namespace, project)

      expect(first('.merge-request')).to have_content milestone.title

      find('#check_all_issues').click
      find('.issues_bulk_update .js-milestone-select').click

      find('.dropdown-menu-milestone a', text: "No Milestone").click
      click_update_merge_requests_button

      expect(find('.merge-request:first-child')).not_to have_content milestone.title
    end
  end

  def click_update_assignee_button
    find('.js-update-assignee').click
    wait_for_ajax
  end

  def click_update_merge_requests_button
    find('.update_selected_issues').click
    wait_for_ajax
  end
end
