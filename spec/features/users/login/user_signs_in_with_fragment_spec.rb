# frozen_string_literal: true

require 'spec_helper'

# A URL fragment (e.g. #L7) is never sent to the server, so the JS re-applies it to the
# server-built 2FA form action and final redirect to carry it onto the destination.
#
# Selenium's current_url fragment handling is unreliable, so the landing fragment is read with
# `page.evaluate_script('window.location.hash')` rather than matched against current_url.
RSpec.describe 'Login preserves URL fragment through 2FA',
  :js, :with_current_organization, :clean_gitlab_redis_sessions, feature_category: :system_access do
  include Features::TwoFactorHelpers
  include EmailHelpers

  let(:anchor) { 'L7' }
  let(:app_id) { "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}" }
  let(:namespace) { create(:namespace, owner: user) }
  let(:project) { create(:project, :private, namespace: namespace, organization: current_organization) }
  let(:deep_link) { project_path(project, anchor: anchor) }

  # Visit a private deep link while signed out. The server stores the redirect path (without the
  # fragment) and bounces to the sign-in form; the browser carries the fragment onto that URL.
  # Fill and submit the password form in place - do not re-visit the sign-in path, which would
  # drop the fragment.
  def start_sign_in_from_deep_link
    visit deep_link

    expect(page).to have_field('user_login')

    fill_in 'user_login', with: user.username
    fill_in 'user_password', with: user.password
    click_button 'Sign in'
  end

  def enter_otp(code)
    fill_in 'user_otp_attempt', with: code
    click_button _('Verify code')
  end

  def expect_landed_on_deep_link
    expect(page).to have_current_path(project_path(project), ignore_query: true)
    expect(page.evaluate_script('window.location.hash')).to eq("##{anchor}")
  end

  context 'with a TOTP user', :freeze_time do
    let(:user) { create(:user, :two_factor) }

    it 'lands on the deep link fragment after entering the one-time code' do
      start_sign_in_from_deep_link

      enter_otp(user.current_otp)

      expect_landed_on_deep_link
    end

    it 'lands on the deep link fragment after entering a recovery code' do
      codes = user.generate_otp_backup_codes!
      user.save!(touch: false)

      start_sign_in_from_deep_link

      find_by_testid('recovery-button').click
      fill_in s_('TwoFactorAuth|Recovery code'), with: codes.sample
      click_button _('Verify code')

      expect_landed_on_deep_link
    end
  end

  context 'with a WebAuthn user' do
    let(:user) { create(:user, :two_factor_via_webauthn, organization: current_organization) }

    before do
      allow(WebAuthn.configuration.relying_party).to receive(:allowed_origins).and_return([app_id])
    end

    it 'lands on the deep link fragment after the device responds' do
      start_sign_in_from_deep_link

      webauthn_device = add_webauthn_device(app_id, user)
      webauthn_device.respond_to_webauthn_authentication

      expect_landed_on_deep_link
    end
  end

  # Email OTP is not a standalone factor; it is reached as a fallback from a primary 2FA factor
  # (see two_factor_user_spec.rb). Here the WebAuthn user switches to it via the "Email code" button.
  context 'when WebAuthn falls back to email OTP', :freeze_time do
    let(:user) do
      create(:user, :two_factor_via_webauthn, email_otp_required_after: 1.day.ago, organization: current_organization)
    end

    before do
      stub_application_setting(email_otp_enabled: true)
      allow(WebAuthn.configuration.relying_party).to receive(:allowed_origins).and_return([app_id])
      ActionMailer::Base.deliveries.clear
    end

    it 'lands on the deep link fragment after verifying the emailed code' do
      start_sign_in_from_deep_link

      click_button s_('TwoFactorAuth|Email code')

      perform_enqueued_jobs do
        expect(page).to have_field(s_('IdentityVerification|Verification code'))

        # The Email code button auto-sends on mount, enqueuing the mailer before this block, so
        # drain any already-enqueued jobs while polling for the mail.
        mail = wait_for('mail found for user') do
          flush_enqueued_jobs
          find_email_for(user)
        end
        code = mail.body.parts.first.to_s[/\d{#{Users::EmailVerification::GenerateTokenService::TOKEN_LENGTH}}/o]

        fill_in s_('IdentityVerification|Verification code'), with: code
        click_button s_('IdentityVerification|Verify code')
      end

      expect_landed_on_deep_link
    end
  end
end
