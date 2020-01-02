# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard Issues' do
  include FilteredSearchHelpers

  let(:current_user) { create :user }
  let(:user) { current_user } # Shared examples depend on this being available
  let!(:public_project) { create(:project, :public) }
  let(:project) { create(:project) }
  let(:project_with_issues_disabled) { create(:project, :issues_disabled) }
  let!(:authored_issue) { create :issue, author: current_user, project: project }
  let!(:authored_issue_on_public_project) { create :issue, author: current_user, project: public_project }
  let!(:assigned_issue) { create :issue, assignees: [current_user], project: project }
  let!(:other_issue) { create :issue, project: project }

  before do
    [project, project_with_issues_disabled].each { |project| project.add_maintainer(current_user) }
    sign_in(current_user)
    visit issues_dashboard_path(assignee_username: current_user.username)
  end

  describe 'issues' do
    it 'shows issues assigned to current user' do
      expect(page).to have_content(assigned_issue.title)
      expect(page).not_to have_content(authored_issue.title)
      expect(page).not_to have_content(other_issue.title)
    end

    it 'shows issues when current user is author', :js do
      reset_filters
      input_filtered_search("author=#{current_user.to_reference}")

      expect(page).to have_content(authored_issue.title)
      expect(page).to have_content(authored_issue_on_public_project.title)
      expect(page).not_to have_content(assigned_issue.title)
      expect(page).not_to have_content(other_issue.title)
    end

    it 'state filter tabs work' do
      find('#state-closed').click
      expect(page).to have_current_path(issues_dashboard_url(assignee_username: current_user.username, state: 'closed'), url: true)
    end

    it_behaves_like "it has an RSS button with current_user's feed token"
    it_behaves_like "an autodiscoverable RSS feed with current_user's feed token"
  end

  describe 'new issue dropdown' do
    it 'shows projects only with issues feature enabled', :js do
      find('.new-project-item-select-button').click

      page.within('.select2-results') do
        expect(page).to have_content(project.full_name)
        expect(page).not_to have_content(project_with_issues_disabled.full_name)
      end
    end

    it 'shows the new issue page', :js do
      find('.new-project-item-select-button').click

      wait_for_requests

      project_path = "/#{project.full_path}"
      project_json = { name: project.full_name, url: project_path }.to_json

      # simulate selection, and prevent overlap by dropdown menu
      first('.project-item-select', visible: false)
      execute_script("$('.project-item-select').val('#{project_json}').trigger('change');")
      find('#select2-drop-mask', visible: false)
      execute_script("$('#select2-drop-mask').remove();")

      find('.new-project-item-link').click

      expect(page).to have_current_path("#{project_path}/issues/new")

      page.within('#content-body') do
        expect(page).to have_selector('.issue-form')
      end
    end
  end
end
