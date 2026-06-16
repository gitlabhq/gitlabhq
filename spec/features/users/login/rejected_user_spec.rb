# frozen_string_literal: true

require 'spec_helper'

# Sign-in attempts that are rejected because of a property of the user
# account itself: blocked accounts, the ghost user, and users with a
# password on the disallowed-password list.
#
# Add tests here when the precondition is "the user record is in a
# state that should refuse sign-in regardless of credentials".

RSpec.describe 'Login', :with_current_organization, :clean_gitlab_redis_sessions, :aggregate_failures, feature_category: :system_access do
  include UserLoginHelper
  include SessionHelpers

  before do
    stub_authentication_activity_metrics(debug: true)
  end

  describe 'with a blocked account', :js do
    it 'prevents the user from logging in' do
      expect(authentication_metrics)
        .to increment(:user_blocked_counter)
        .and increment(:user_unauthenticated_counter)
        .and increment(:user_session_destroyed_counter).twice

      user = create(:user, :blocked)

      submit_sign_in_form_for(user)

      expect(page).to have_content('Your account has been blocked.')
    end

    it 'does not update Devise trackable attributes' do
      expect(authentication_metrics)
        .to increment(:user_blocked_counter)
        .and increment(:user_unauthenticated_counter)
        .and increment(:user_session_destroyed_counter).twice

      user = create(:user, :blocked)

      submit_sign_in_form_for(user)

      expect(page).to have_content('Your account has been blocked.')
      expect(user.reload.sign_in_count).to eq(0)
    end
  end

  describe 'with a disallowed password', :js do
    let(:user) { create(:user, :disallowed_password) }

    before do
      expect(authentication_metrics) # rubocop:disable RSpec/ExpectInHook -- message-expectation mock setup for the metric, must be installed before each example's sign-in attempt fires
        .to increment(:user_unauthenticated_counter)
        .and increment(:user_password_invalid_counter)
    end

    it 'disallows login' do
      submit_sign_in_form_for(user, password: user.password)

      expect(page).to have_content('Invalid login or password.')
    end

    it 'does not update Devise trackable attributes' do
      submit_sign_in_form_for(user, password: user.password)

      expect(page).to have_content('Invalid login or password.')
      expect(user.reload.sign_in_count).to eq(0)
    end
  end

  describe 'with the ghost user', :js do
    let_it_be(:ghost_user) { create(:user, user_type: :ghost) }

    it 'disallows login' do
      expect(authentication_metrics)
        .to increment(:user_unauthenticated_counter)
        .and increment(:user_session_destroyed_counter).twice

      submit_sign_in_form_for(ghost_user)

      expect(page).to have_content(
        'Your account does not have the required permission to login. ' \
          'Please contact your GitLab administrator if you think this is an error.'
      )
    end

    it 'does not update Devise trackable attributes' do
      expect(authentication_metrics)
        .to increment(:user_unauthenticated_counter)
        .and increment(:user_session_destroyed_counter).twice

      submit_sign_in_form_for(ghost_user)

      expect(page).to have_content(
        'Your account does not have the required permission to login. ' \
          'Please contact your GitLab administrator if you think this is an error.'
      )
      expect(ghost_user.reload.sign_in_count).to eq(0)
    end
  end
end
