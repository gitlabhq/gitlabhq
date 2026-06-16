# frozen_string_literal: true

require 'spec_helper'

# Sign-in flows that run during first-time GitLab setup, before any
# regular user exists. Tests for the initial-admin password creation
# flow and for sign-in-page rendering in the empty-database state.
#
# Add tests here when the precondition is "no users exist yet" or
# "the instance has not been initialised".

RSpec.describe 'Login', :with_current_organization, :clean_gitlab_redis_sessions, :aggregate_failures, feature_category: :system_access do
  include UserLoginHelper
  include SessionHelpers

  before do
    stub_authentication_activity_metrics(debug: true)
  end

  describe 'initial login after setup', :js do
    it 'allows the initial admin to create a password' do
      expect(authentication_metrics)
        .to increment(:user_authenticated_counter)

      # This behavior is dependent on there only being one user
      User.delete_all

      user = create(:admin, password_automatically_set: true)

      visit root_path
      expect(page).to have_current_path new_admin_initial_setup_path, ignore_query: true
      expect(page).to have_content('Administrator Account Setup')

      fill_in 'user_email',                 with: 'admin_specs@example.com'
      fill_in 'user_password',              with: user.password
      fill_in 'user_password_confirmation', with: user.password
      click_button 'Set up root account'

      expect(page).to have_current_path new_user_session_path, ignore_query: true
      expect(page).to have_content('Initial account configured! Please sign in.')

      gitlab_sign_in(user.reload)

      expect_single_session_with_authenticated_ttl
      expect(page).to have_current_path root_path, ignore_query: true
    end

    it 'does not show flash messages when login page' do
      visit root_path
      expect(page).not_to have_content('Sign in or sign up before continuing.')
    end
  end
end
