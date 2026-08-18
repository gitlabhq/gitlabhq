# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User toggles subscription", :js, feature_category: :team_planning do
  let_it_be(:project) { create(:project_empty_repo, :public) }
  let_it_be(:author) { create(:user) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:non_member) { create(:user) }
  let_it_be(:issue) { create(:issue, project: project, author: author) }

  context 'when the user is not logged in' do
    before do
      visit(project_issue_path(project, issue))
    end

    it 'does not display the notifications button' do
      expect(page).to have_content(issue.title)

      expect(page).to have_no_testid('subscribe-button')
    end
  end

  context 'when the user is a project member' do
    before do
      sign_in(developer)
      visit(project_issue_path(project, issue))
    end

    it 'subscribes and unsubscribes', :aggregate_failures do
      wait_for_requests

      expect(page).to have_css('[data-testid="subscribe-button"][data-subscribed="false"]')
      find_by_testid('subscribe-button').click

      expect(page).to have_css('.gl-toast', text: _('Notifications turned on.'))
      expect(page).to have_css('[data-testid="subscribe-button"][data-subscribed="true"]')

      find_by_testid('subscribe-button').click

      expect(page).to have_css('.gl-toast', text: _('Notifications turned off.'))
      expect(page).to have_css('[data-testid="subscribe-button"][data-subscribed="false"]')
    end
  end

  context 'when the user is not a project member' do
    before do
      sign_in(non_member)
      visit(project_issue_path(project, issue))
    end

    it 'subscribes to the issue', :aggregate_failures do
      wait_for_requests

      expect(page).to have_css('[data-testid="subscribe-button"][data-subscribed="false"]')
      find_by_testid('subscribe-button').click

      expect(page).to have_css('.gl-toast', text: _('Notifications turned on.'))
      expect(page).to have_css('[data-testid="subscribe-button"][data-subscribed="true"]')
    end
  end
end
