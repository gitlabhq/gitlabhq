# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User manages subscription', :js, feature_category: :code_review_workflow do
  let(:project) { create(:project, :public, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:user) { create(:user) }
  let(:notifications_todos_buttons_enabled) { false }

  before do
    stub_feature_flags(notifications_todos_buttons: notifications_todos_buttons_enabled)
    project.add_maintainer(user)
    sign_in(user)

    visit(merge_request_path(merge_request))
  end

  it 'toggles subscription' do
    wait_for_requests

    find('#new-actions-header-dropdown button').click

    expect(page).to have_selector('.gl-toggle:not(.is-checked)')
    find('[data-testid="notification-toggle"] .gl-toggle').click

    wait_for_requests

    expect(page).to have_selector('.gl-toggle.is-checked')
    find('[data-testid="notification-toggle"] .gl-toggle').click

    wait_for_requests

    expect(page).to have_selector('.gl-toggle:not(.is-checked)')
  end

  context 'with notifications_todos_buttons feature flag enabled' do
    let(:notifications_todos_buttons_enabled) { true }

    it 'toggles subscription' do
      wait_for_requests

      find('[data-testid="subscribe-button"]').click
      expect(page).to have_selector('[data-testid="notifications-off-icon"]')

      find('[data-testid="subscribe-button"]').click
      expect(page).to have_selector('[data-testid="notifications-icon"]')
    end
  end
end
