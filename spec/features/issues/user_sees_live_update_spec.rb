# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issues > User sees live update', :js, feature_category: :team_planning do
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
    it 'shows the confidentiality status that can be turned off' do
      issue = create(:issue, :confidential, project: project)

      visit project_issue_path(project, issue)
      wait_for_requests

      expect(page).to have_css('.gl-badge', text: 'Confidential')

      click_button 'Issue actions'
      within '#new-actions-header-dropdown' do
        click_button 'Turn off confidentiality'
      end

      visit project_issue_path(project, issue)
      wait_for_requests

      expect(page).not_to have_css('.gl-badge', text: 'Confidential')
    end
  end
end
