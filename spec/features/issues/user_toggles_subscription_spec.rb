# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User toggles subscription", :js, feature_category: :team_planning do
  let(:project) { create(:project_empty_repo, :public) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:issue) { create(:issue, project: project, author: user) }

  before do
    stub_feature_flags(work_item_view_for_issues: true)
  end

  context 'user is not logged in' do
    before do
      stub_feature_flags(notifications_todos_buttons: false)
      visit(project_issue_path(project, issue))
    end

    it 'does not display the Notification toggle' do
      click_button('More actions', match: :first)

      expect(page).not_to have_button('Notifications')
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
      click_button('More actions', match: :first)
      click_button('Notifications')

      expect(page).to have_css('.b-toaster', text: 'Notifications turned off.')
    end
  end

  context 'user is logged in without edit permission' do
    before do
      stub_feature_flags(notifications_todos_buttons: false)
      sign_in(user2)
      visit(project_issue_path(project, issue))
    end

    it 'subscribes to issue' do
      click_button('More actions', match: :first)
      click_button('Notifications')

      expect(page).to have_css('.b-toaster', text: 'Notifications turned on.')
    end
  end

  context 'with notifications_todos_buttons feature flag enabled' do
    before do
      stub_feature_flags(notifications_todos_buttons: true)
      sign_in(user2)

      visit(project_issue_path(project, issue))
    end

    it 'toggles subscription' do
      click_button('Notifications off')
      wait_for_requests

      expect(page).to have_css('.b-toaster', text: 'Notifications turned on.')
      expect(page).to have_button('Notifications on')
    end
  end
end
