# frozen_string_literal: true

require 'spec_helper'

# Sign-in flows when the user has not confirmed their email address.
# Covers the grace period (login allowed with a warning), the
# post-grace-period state (login refused, resend link offered), and
# the resend-confirmation flow itself.
#
# Add tests here when the precondition is "user.confirmed_at is nil"
# (regardless of where in the confirmation grace window we are).

RSpec.describe 'Login', :with_current_organization, :clean_gitlab_redis_sessions, :aggregate_failures, feature_category: :system_access do
  include UserLoginHelper
  include SessionHelpers

  before do
    stub_authentication_activity_metrics(debug: true)
  end

  describe 'with an unconfirmed email address', :js do
    let!(:user) { create(:user, confirmed_at: nil) }
    let(:grace_period) { 2.days }
    let(:alert_title) { 'Please confirm your email address' }
    let(:alert_message) do
      'To continue, you need to select the link in the confirmation email we sent to verify ' \
        "your email address. If you didn't get our email, select Resend confirmation email"
    end

    before do
      stub_application_setting_enum('email_confirmation_setting', 'hard')
      allow(User).to receive(:allow_unconfirmed_access_for).and_return grace_period
    end

    context 'when within the grace period' do
      before do
        stub_application_setting_enum('email_confirmation_setting', 'soft')
      end

      it 'allows to login' do
        expect(authentication_metrics).to increment(:user_authenticated_counter)

        gitlab_sign_in(user)

        expect(page).not_to have_content(alert_title)
        expect(page).not_to have_content(alert_message)
        expect(page).not_to have_link('Resend confirmation email', href: new_user_confirmation_path)
      end
    end

    context 'when the confirmation grace period is expired' do
      it 'prevents the user from logging in and renders a resend confirmation email link', :js do
        travel_to((grace_period + 1.day).from_now) do
          expect(authentication_metrics)
            .to increment(:user_unauthenticated_counter)
            .and increment(:user_session_destroyed_counter).twice

          submit_sign_in_form_for(user)

          expect(page).to have_content(alert_title)
          expect(page).to have_content(alert_message)
          expect(page).to have_link('Resend confirmation email', href: new_user_confirmation_path)
        end
      end
    end

    context 'when resending the confirmation email' do
      let_it_be(:user) { create(:user) }

      it 'redirects to the "almost there" page' do
        visit new_user_confirmation_path
        fill_in 'user_email', with: user.email
        click_button 'Resend'

        expect(page).to have_current_path users_almost_there_path, ignore_query: true
      end
    end
  end

  context 'when sending confirmation email and not yet confirmed', :js do
    let!(:user) { create(:user, confirmed_at: nil) }
    let(:grace_period) { 2.days }
    let(:alert_title) { 'Please confirm your email address' }
    let(:alert_message) do
      'To continue, you need to select the link in the confirmation email we sent to verify ' \
        "your email address. If you didn't get our email, select Resend confirmation email"
    end

    before do
      stub_application_setting_enum('email_confirmation_setting', 'soft')
      allow(User).to receive(:allow_unconfirmed_access_for).and_return grace_period
    end

    it 'allows login and shows a flash warning to confirm the email address' do
      expect(authentication_metrics).to increment(:user_authenticated_counter)

      gitlab_sign_in(user)

      expect(page).to have_current_path root_path, ignore_query: true
      expect(page).to have_content(
        "Please check your email (#{user.email}) to verify that you own this address " \
          'and unlock the power of CI/CD.'
      )
    end

    context "when not having confirmed within Devise's allow_unconfirmed_access_for time" do
      it 'does not allow login and shows a flash alert to confirm the email address', :js do
        travel_to((grace_period + 1.day).from_now) do
          expect(authentication_metrics)
            .to increment(:user_unauthenticated_counter)
            .and increment(:user_session_destroyed_counter).twice

          submit_sign_in_form_for(user)

          expect(page).to have_current_path new_user_session_path, ignore_query: true
          expect(page).to have_content(alert_title)
          expect(page).to have_content(alert_message)
          expect(page).to have_link('Resend confirmation email', href: new_user_confirmation_path)
        end
      end
    end
  end
end
