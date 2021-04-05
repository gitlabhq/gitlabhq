# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issues > User sees live update', :js do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { project.creator }

  before do
    sign_in(user)
  end

  describe 'title issue#show' do
    it 'updates the title' do
      issue = create(:issue, author: user, assignees: [user], project: project, title: 'new title')

      visit project_issue_path(project, issue)

      expect(page).to have_text("new title")

      issue.update!(title: "updated title")

      wait_for_requests
      expect(page).to have_text("updated title")
    end
  end

  describe 'confidential issue#show' do
    it 'shows confidential sibebar information as confidential and can be turned off', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/254644' do
      issue = create(:issue, :confidential, project: project)

      visit project_issue_path(project, issue)

      expect(page).to have_css('.issuable-note-warning')
      expect(find('.issuable-sidebar-item.confidentiality')).to have_css('.is-active')
      expect(find('.issuable-sidebar-item.confidentiality')).not_to have_css('.not-active')

      find('.confidential-edit').click
      expect(page).to have_css('.sidebar-item-warning-message')

      within('.sidebar-item-warning-message') do
        find('[data-testid="confidential-toggle"]').click
      end

      wait_for_requests

      visit project_issue_path(project, issue)

      expect(page).not_to have_css('.is-active')
    end
  end
end
