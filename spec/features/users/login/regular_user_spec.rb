# frozen_string_literal: true

require 'spec_helper'

# Sign-in flows for a regular user without 2FA: successful login,
# invalid password, session expiry, remember-me extension, password
# reset interplay, expired password redirect.
#
# Add tests here when the precondition is "ordinary user, no 2FA,
# default config" and the test is about the basic password sign-in
# flow or its immediate side-effects (session, remember-me, password
# state).

RSpec.describe 'Login', :with_current_organization, :clean_gitlab_redis_sessions, :aggregate_failures, feature_category: :system_access do
  include UserLoginHelper
  include SessionHelpers

  before do
    stub_authentication_activity_metrics(debug: true)
  end

  describe 'password reset token after successful sign in', :js do
    it 'invalidates password reset token' do
      expect(authentication_metrics)
        .to increment(:user_authenticated_counter)

      user = create(:user)

      expect(user.reset_password_token).to be_nil

      visit new_user_password_path
      fill_in 'user_email', with: user.email
      click_button 'Reset password'

      expect(page).to have_content(
        'If your email address exists in our database, ' \
          'you will receive a password recovery link at your email address in a few minutes.'
      )

      user.reload
      expect(user.reset_password_token).not_to be_nil

      gitlab_sign_in(user)
      expect(page).to have_current_path root_path, ignore_query: true

      user.reload
      expect(user.reset_password_token).to be_nil
    end
  end

  describe 'without two-factor authentication' do
    it 'renders sign in text for providers' do
      visit new_user_session_path

      expect(page).to have_content(_('or sign in with'))
    end

    it 'displays the remember me checkbox' do
      visit new_user_session_path

      expect(page).to have_content(_('Remember me'))
    end

    context 'when remember me is not enabled' do
      before do
        stub_application_setting(remember_me_enabled: false)
      end

      it 'does not display the remember me checkbox' do
        visit new_user_session_path

        expect(page).not_to have_content(_('Remember me'))
      end
    end

    context 'with correct username and password', :js do
      let(:user) { create(:user) }

      it 'allows basic login' do
        expect(authentication_metrics)
          .to increment(:user_authenticated_counter)

        gitlab_sign_in(user)

        expect_single_session_with_authenticated_ttl
        expect(page).to have_current_path root_path, ignore_query: true
        expect(page).not_to have_content(I18n.t('devise.failure.already_authenticated'))
      end

      it 'does not show already signed in message when opening sign in page after login' do
        expect(authentication_metrics)
          .to increment(:user_authenticated_counter)

        gitlab_sign_in(user)
        visit new_user_session_path

        expect_single_session_with_authenticated_ttl
        expect(page).not_to have_content(I18n.t('devise.failure.already_authenticated'))
      end

      it 'triggers ActiveSession.cleanup for the user' do
        expect(authentication_metrics)
          .to increment(:user_authenticated_counter)
        expect(ActiveSession).to receive(:cleanup).with(user).once.and_call_original

        gitlab_sign_in(user)
      end

      context 'when the session expires' do
        it 'signs the user out' do
          expect(authentication_metrics)
            .to increment(:user_authenticated_counter)

          gitlab_sign_in(user)
          expire_session
          visit root_path

          expect(page).to have_current_path new_user_session_path
        end

        it 'extends the session when using remember me' do
          expect(authentication_metrics)
            .to increment(:user_authenticated_counter).twice

          gitlab_sign_in(user, remember: true)
          wait_for_requests # rubocop:disable RSpec/AvoidWaitForRequests -- async auth requests must settle before expire_session to keep the authentication counter deterministic
          expire_session

          visit root_path
          expect(page).to have_current_path root_path
        end

        it 'does not extend the session when remember me is not enabled' do
          expect(authentication_metrics)
            .to increment(:user_authenticated_counter)

          gitlab_sign_in(user, remember: true)
          expire_session
          stub_application_setting(remember_me_enabled: false)

          visit root_path
          expect(page).to have_current_path new_user_session_path
        end
      end

      context 'when the users password is expired' do
        before do
          user.update!(password_expires_at: Time.zone.parse('2018-05-08 11:29:46 UTC'))
        end

        it 'asks for a new password' do
          expect(authentication_metrics)
            .to increment(:user_authenticated_counter)

          visit new_user_session_path

          gitlab_sign_in(user)

          expect(page).to have_current_path(new_user_settings_password_path, ignore_query: true)
        end
      end
    end

    context 'with correct username and invalid password', :js do
      let(:user) { create(:user) }

      it 'blocks invalid login' do
        expect(authentication_metrics)
          .to increment(:user_unauthenticated_counter)
          .and increment(:user_password_invalid_counter)

        submit_sign_in_form_for(user, password: 'incorrect-password')

        expect_single_session_with_short_ttl
        expect(page).to have_content('Invalid login or password.')
        expect(user.reload.failed_attempts).to eq(1)
      end
    end
  end
end
