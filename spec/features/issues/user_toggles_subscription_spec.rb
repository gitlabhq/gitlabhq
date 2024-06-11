# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User toggles subscription", :js, feature_category: :team_planning do
  let(:project) { create(:project_empty_repo, :public) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:issue) { create(:issue, project: project, author: user) }

  context 'user is not logged in' do
    before do
      stub_feature_flags(notifications_todos_buttons: false)
      visit(project_issue_path(project, issue))
    end

    it 'does not display the Notification toggle' do
      find('.detail-page-header-actions .gl-new-dropdown-toggle').click

      expect(page).not_to have_selector('.is-checked:not(.is-checked)')
    end
  end

  context 'user is logged in' do
    before do
      stub_feature_flags(notifications_todos_buttons: false)
      project.add_developer(user)
      sign_in(user)
      visit(project_issue_path(project, issue))
    end

    it 'unsubscribes from issue' do
      find('.detail-page-header-actions .gl-new-dropdown-toggle').click

      within_testid('notification-toggle') do
        subscription_button = find_by_testid('toggle-wrapper')

        # Check we're subscribed.
        expect(subscription_button).to have_css("button.is-checked")

        # Toggle subscription.
        subscription_button.find('button').click
        wait_for_requests

        # Check we're unsubscribed.
        expect(subscription_button).to have_css("button:not(.is-checked)")
      end
    end
  end

  context 'user is logged in without edit permission' do
    before do
      stub_feature_flags(notifications_todos_buttons: false)
      sign_in(user2)

      visit(project_issue_path(project, issue))
    end

    it 'subscribes to issue' do
      find('.detail-page-header-actions .gl-new-dropdown-toggle').click

      within_testid('notification-toggle') do
        subscription_button = find_by_testid('toggle-wrapper')

        # Check we're not subscribed.
        expect(subscription_button).to have_css("button:not(.is-checked)")

        # Toggle subscription.
        subscription_button.find('button').click
        wait_for_requests

        # Check we're subscribed.
        expect(subscription_button).to have_css("button.is-checked")
      end
    end
  end

  context 'with notifications_todos_buttons feature flag enabled' do
    before do
      stub_feature_flags(notifications_todos_buttons: true)
      sign_in(user2)

      visit(project_issue_path(project, issue))
    end

    it 'toggles subscription', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/435076' do
      subscription_button = find_by_testid('subscribe-button')

      expect(page).to have_selector("button[title='Notifications off']")
      subscription_button.click
      wait_for_requests

      expect(page).to have_selector("button[title='Notifications on']")
    end
  end
end
