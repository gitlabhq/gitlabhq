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

      using_session :other_session do
        visit project_issue_path(project, issue)

        expect(page).to have_css('h1', text: 'new title')
      end

      sign_in(user)
      visit project_issue_path(project, issue)

      click_button 'Edit title and description'
      fill_in 'Title', with: 'updated title'
      click_button 'Save changes'

      using_session :other_session do
        expect(page).to have_css('h1', text: 'updated title')
      end
    end
  end

  describe 'confidential issue#show' do
    it 'shows the confidentiality status that can be turned off' do
      issue = create(:issue, :confidential, project: project)

      visit project_issue_path(project, issue)
      wait_for_requests

      expect(page).to have_css('.gl-badge', text: 'Confidential')

      click_button 'More actions', match: :first
      click_button 'Turn off confidentiality'

      expect(page).not_to have_css('.gl-badge', text: 'Confidential')
    end
  end
end
