# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Login', :clean_gitlab_redis_sessions, :aggregate_failures, feature_category: :system_access do
  include TermsHelper
  include UserLoginHelper
  include SessionHelpers

  before do
    stub_authentication_activity_metrics(debug: true)
  end

  describe 'password reset token after successful sign in' do
    it 'invalidates password reset token' do
      expect(authentication_metrics)
        .to increment(:user_authenticated_counter)

      user = create(:user)

      expect(user.reset_password_token).to be_nil

      visit new_user_password_path
      fill_in 'user_email', with: user.email
      click_button 'Reset password'

      user.reload
      expect(user.reset_password_token).not_to be_nil

      gitlab_sign_in(user)
      expect(page).to have_current_path root_path, ignore_query: true

      user.reload
      expect(user.reset_password_token).to be_nil
    end
  end

  describe 'initial login after setup' do
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
      expect(page).not_to have_content('You need to sign in or sign up before continuing.')
    end
  end

  describe 'with a blocked account' do
    it 'prevents the user from logging in' do
      expect(authentication_metrics)
        .to increment(:user_blocked_counter)
        .and increment(:user_unauthenticated_counter)
        .and increment(:user_session_destroyed_counter).twice

      user = create(:user, :blocked)

      gitlab_sign_in(user)

      expect(page).to have_content('Your account has been blocked.')
    end

    it 'does not update Devise trackable attributes' do
      expect(authentication_metrics)
        .to increment(:user_blocked_counter)
        .and increment(:user_unauthenticated_counter)
        .and increment(:user_session_destroyed_counter).twice

      user = create(:user, :blocked)

      expect { gitlab_sign_in(user) }.not_to change { user.reload.sign_in_count }
    end
  end

  describe 'with an unconfirmed email address' do
    let!(:user) { create(:user, confirmed_at: nil) }
    let(:grace_period) { 2.days }
    let(:alert_title) { 'Please confirm your email address' }
    let(:alert_message) { "To continue, you need to select the link in the confirmation email we sent to verify your email address. If you didn't get our email, select Resend confirmation email" }

    before do
      stub_application_setting_enum('email_confirmation_setting', 'hard')
      allow(User).to receive(:allow_unconfirmed_access_for).and_return grace_period
    end

    context 'within the grace period' do
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

          gitlab_sign_in(user)

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

  describe 'with a disallowed password' do
    let(:user) { create(:user, :disallowed_password) }

    before do
      expect(authentication_metrics)
        .to increment(:user_unauthenticated_counter)
        .and increment(:user_password_invalid_counter)
    end

    it 'disallows login' do
      gitlab_sign_in(user, password: user.password)

      expect(page).to have_content('Invalid login or password.')
    end

    it 'does not update Devise trackable attributes' do
      expect { gitlab_sign_in(user, password: user.password) }
        .not_to change { user.reload.sign_in_count }
    end
  end

  describe 'with the ghost user' do
    it 'disallows login' do
      expect(authentication_metrics)
        .to increment(:user_unauthenticated_counter)
        .and increment(:user_password_invalid_counter)

      gitlab_sign_in(Users::Internal.ghost)

      expect(page).to have_content('Invalid login or password.')
    end

    it 'does not update Devise trackable attributes' do
      expect(authentication_metrics)
        .to increment(:user_unauthenticated_counter)
        .and increment(:user_password_invalid_counter)

      expect { gitlab_sign_in(Users::Internal.ghost) }
        .not_to change { Users::Internal.ghost.reload.sign_in_count }
    end
  end

  describe 'with OneTrust authentication' do
    before do
      stub_config(extra: { one_trust_id: SecureRandom.uuid })
    end

    it 'has proper Content-Security-Policy headers' do
      visit root_path

      expect(response_headers['Content-Security-Policy']).to include('https://cdn.cookielaw.org https://*.onetrust.com')
    end
  end

  describe 'with two-factor authentication', :js do
    def enter_code(code, only_two_factor_webauthn_enabled: false)
      if only_two_factor_webauthn_enabled
        # When this button is visible we know that the JavaScript functionality is ready.
        find_button(_('Try again?'))
        click_button _("Sign in via 2FA code")
      end

      fill_in _('Enter verification code'), with: code
      click_button _('Verify code')
    end

    shared_examples_for 'can login with recovery codes' do |only_two_factor_webauthn_enabled: false|
      context 'using backup code' do
        let(:codes) { user.generate_otp_backup_codes! }

        before do
          expect(codes.size).to eq 10

          # Ensure the generated codes get saved
          user.save!(touch: false)
        end

        context 'with valid code' do
          it 'allows login' do
            expect(authentication_metrics)
              .to increment(:user_authenticated_counter)
              .and increment(:user_two_factor_authenticated_counter)

            enter_code(codes.sample, only_two_factor_webauthn_enabled: only_two_factor_webauthn_enabled)

            expect(page).to have_current_path root_path, ignore_query: true
          end

          it 'invalidates the used code' do
            expect(authentication_metrics)
              .to increment(:user_authenticated_counter)
              .and increment(:user_two_factor_authenticated_counter)

            expect { enter_code(codes.sample, only_two_factor_webauthn_enabled: only_two_factor_webauthn_enabled) }
              .to change { user.reload.otp_backup_codes.size }.by(-1)
          end

          it 'invalidates backup codes twice in a row' do
            expect(authentication_metrics)
              .to increment(:user_authenticated_counter).twice
              .and increment(:user_two_factor_authenticated_counter).twice
              .and increment(:user_session_destroyed_counter)

            random_code = codes.delete(codes.sample)
            expect { enter_code(random_code, only_two_factor_webauthn_enabled: only_two_factor_webauthn_enabled) }
              .to change { user.reload.otp_backup_codes.size }.by(-1)

            gitlab_sign_out
            gitlab_sign_in(user)

            expect { enter_code(codes.sample, only_two_factor_webauthn_enabled: only_two_factor_webauthn_enabled) }
              .to change { user.reload.otp_backup_codes.size }.by(-1)
          end

          it 'triggers ActiveSession.cleanup for the user' do
            expect(authentication_metrics)
              .to increment(:user_authenticated_counter)
              .and increment(:user_two_factor_authenticated_counter)
            expect(ActiveSession).to receive(:cleanup).with(user).once.and_call_original

            enter_code(codes.sample, only_two_factor_webauthn_enabled: only_two_factor_webauthn_enabled)
          end
        end

        context 'with invalid code' do
          it 'blocks login' do
            # TODO, invalid two factor authentication does not increment
            # metrics / counters, see gitlab-org/gitlab-ce#49785

            code = codes.sample
            expect(user.invalidate_otp_backup_code!(code)).to eq true

            user.save!(touch: false)
            expect(user.reload.otp_backup_codes.size).to eq 9

            enter_code(code, only_two_factor_webauthn_enabled: only_two_factor_webauthn_enabled)
            expect(page).to have_content('Invalid two-factor code.')
            expect(user.reload.failed_attempts).to eq(1)
          end
        end
      end
    end

    # Freeze time to prevent failures when time between code being entered and
    # validated greater than otp_allowed_drift
    context 'with valid username/password', :freeze_time do
      let(:user) { create(:user, :two_factor) }

      before do
        gitlab_sign_in(user, remember: true)
      end

      it 'does not show a "You are already signed in." error message' do
        expect(authentication_metrics)
          .to increment(:user_authenticated_counter)
          .and increment(:user_two_factor_authenticated_counter)

        enter_code(user.current_otp)

        expect(page).not_to have_content(I18n.t('devise.failure.already_authenticated'))
        expect_single_session_with_authenticated_ttl
      end

      it 'does not allow sign-in if the user password is updated before entering a one-time code' do
        user.update!(password: User.random_password)

        enter_code(user.current_otp)

        expect(page).to have_content('An error occurred. Please sign in again.')
      end

      context 'using one-time code' do
        it 'allows login with valid code' do
          expect(authentication_metrics)
            .to increment(:user_authenticated_counter)
            .and increment(:user_two_factor_authenticated_counter)

          enter_code(user.current_otp)

          expect_single_session_with_authenticated_ttl
          expect(page).to have_current_path root_path, ignore_query: true
        end

        it 'persists remember_me value via hidden field' do
          field = first('input#user_remember_me', visible: false)

          expect(field.value).to eq '1'
        end

        it 'blocks login with invalid code' do
          # TODO invalid 2FA code does not generate any events
          # See gitlab-org/gitlab-ce#49785

          enter_code('foo')

          expect(page).to have_content('Invalid two-factor code')
        end

        it 'allows login with invalid code, then valid code' do
          expect(authentication_metrics)
            .to increment(:user_authenticated_counter)
            .and increment(:user_two_factor_authenticated_counter)

          enter_code('foo')
          expect(page).to have_content('Invalid two-factor code')

          enter_code(user.current_otp)

          expect_single_session_with_authenticated_ttl
          expect(page).to have_current_path root_path, ignore_query: true
        end

        it 'triggers ActiveSession.cleanup for the user' do
          expect(authentication_metrics)
            .to increment(:user_authenticated_counter)
            .and increment(:user_two_factor_authenticated_counter)
          expect(ActiveSession).to receive(:cleanup).with(user).once.and_call_original

          enter_code(user.current_otp)
        end
      end

      context 'when user with TOTP enabled' do
        let(:user) { create(:user, :two_factor) }

        include_examples 'can login with recovery codes'
      end

      context 'when user with only Webauthn enabled' do
        let(:user) { create(:user, :two_factor_via_webauthn, registrations_count: 1) }

        include_examples 'can login with recovery codes', only_two_factor_webauthn_enabled: true
      end
    end

    context 'when logging in via OAuth' do
      let(:user) { create(:omniauth_user, :two_factor, extern_uid: 'my-uid', provider: 'saml') }
      let(:mock_saml_response) do
        File.read('spec/fixtures/authentication/saml_response.xml')
      end

      before do
        stub_omniauth_saml_config(
          enabled: true,
          auto_link_saml_user: true,
          allow_single_sign_on: ['saml'],
          providers: [mock_saml_config_with_upstream_two_factor_authn_contexts]
        )
      end

      it 'displays the remember me checkbox' do
        visit new_user_session_path

        expect(page).to have_field('js-remember-me-omniauth')
      end

      context 'when remember me is not enabled' do
        before do
          stub_application_setting(remember_me_enabled: false)
        end

        it 'does not display the remember me checkbox' do
          visit new_user_session_path

          expect(page).not_to have_field('js-remember-me-omniauth')
        end
      end

      context 'when authn_context is worth two factors' do
        let(:mock_saml_response) do
          File.read('spec/fixtures/authentication/saml_response.xml')
            .gsub(
              'urn:oasis:names:tc:SAML:2.0:ac:classes:Password',
              'urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorOTPSMS'
            )
        end

        it 'signs user in without prompting for second factor' do
          # TODO, OAuth authentication does not fire events,
          # see gitlab-org/gitlab-ce#49786

          expect(authentication_metrics)
            .to increment(:user_authenticated_counter)
          expect(ActiveSession).to receive(:cleanup).with(user).once.and_call_original

          sign_in_using_saml!

          expect_single_session_with_authenticated_ttl
          expect(page).not_to have_content(_('Enter verification code'))
          expect(page).to have_current_path root_path, ignore_query: true
        end
      end

      # Freeze time to prevent failures when time between code being entered and
      # validated greater than otp_allowed_drift
      context 'when two factor authentication is required', :freeze_time do
        it 'shows 2FA prompt after OAuth login' do
          expect(authentication_metrics)
            .to increment(:user_authenticated_counter)
            .and increment(:user_two_factor_authenticated_counter)
          expect(ActiveSession).to receive(:cleanup).with(user).once.and_call_original

          sign_in_using_saml!

          expect(page).to have_content('Enter verification code')

          enter_code(user.current_otp)

          expect_single_session_with_authenticated_ttl
          expect(page).to have_current_path root_path, ignore_query: true
        end
      end

      def sign_in_using_saml!
        gitlab_sign_in_via('saml', user, 'my-uid', mock_saml_response)
      end
    end
  end

  describe 'with auto_sign_in_with_provider enabled' do
    before do
      stub_omniauth_saml_config(
        enabled: true,
        auto_sign_in_with_provider: 'saml',
        allow_single_sign_on: ['saml']
      )

      allow_next_instance_of(ActionDispatch::Routing::RoutesProxy) do |instance|
        allow(instance).to receive(:user_saml_omniauth_authorize_path)
          .and_return('/api/graphql?my_fake_idp') # A dummy page where we can do a POST request
      end
    end

    it 'redirects to the identity provider', :js do
      visit new_user_session_path

      expect(page.current_url).to end_with('/api/graphql?my_fake_idp')
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

    context 'with correct username and password' do
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

    context 'with correct username and invalid password' do
      let(:user) { create(:user) }

      it 'blocks invalid login' do
        expect(authentication_metrics)
          .to increment(:user_unauthenticated_counter)
          .and increment(:user_password_invalid_counter)

        gitlab_sign_in(user, password: 'incorrect-password')

        expect_single_session_with_short_ttl
        expect(page).to have_content('Invalid login or password.')
        expect(user.reload.failed_attempts).to eq(1)
      end
    end
  end

  describe 'with required two-factor authentication enabled' do
    let(:user) { create(:user) }

    #  TODO: otp_grace_period_started_at

    context 'global setting' do
      before do
        stub_application_setting(require_two_factor_authentication: true)
      end

      context 'with grace period defined' do
        before do
          stub_application_setting(two_factor_grace_period: 48)
        end

        context 'within the grace period' do
          it 'redirects to two-factor configuration page' do
            expect(authentication_metrics)
              .to increment(:user_authenticated_counter)

            gitlab_sign_in(user)

            expect(page).to have_current_path profile_two_factor_auth_path, ignore_query: true
            expect(page).to have_content('The global settings require you to enable Two-Factor Authentication for your account. You need to do this before ')
          end

          it 'allows skipping two-factor configuration' do
            expect(authentication_metrics)
              .to increment(:user_authenticated_counter)

            gitlab_sign_in(user)

            expect(page).to have_current_path profile_two_factor_auth_path, ignore_query: true
            click_link _('Configure it later')
            expect(page).to have_current_path root_path, ignore_query: true
          end
        end

        context 'after the grace period' do
          let(:user) { create(:user, otp_grace_period_started_at: 9999.hours.ago) }

          it 'redirects to two-factor configuration page' do
            expect(authentication_metrics)
              .to increment(:user_authenticated_counter)

            gitlab_sign_in(user)

            expect(page).to have_current_path profile_two_factor_auth_path, ignore_query: true
            expect(page).to have_content(
              'The global settings require you to enable Two-Factor Authentication for your account.'
            )
          end

          it 'disallows skipping two-factor configuration' do
            expect(authentication_metrics)
              .to increment(:user_authenticated_counter)

            gitlab_sign_in(user)

            expect(page).to have_current_path profile_two_factor_auth_path, ignore_query: true
            expect(page).not_to have_link(_('Configure it later'))
          end
        end
      end

      context 'without grace period defined' do
        before do
          stub_application_setting(two_factor_grace_period: 0)
        end

        it 'redirects to two-factor configuration page' do
          expect(authentication_metrics)
            .to increment(:user_authenticated_counter)

          gitlab_sign_in(user)

          expect(page).to have_current_path profile_two_factor_auth_path, ignore_query: true
          expect(page).to have_content(
            'The global settings require you to enable Two-Factor Authentication for your account.'
          )
        end
      end
    end

    context 'group setting' do
      before do
        group1 = create :group, name: 'Group 1', require_two_factor_authentication: true
        group1.add_member(user, GroupMember::DEVELOPER)
        group2 = create :group, name: 'Group 2', require_two_factor_authentication: true
        group2.add_member(user, GroupMember::DEVELOPER)
      end

      context 'with grace period defined' do
        before do
          stub_application_setting(two_factor_grace_period: 48)
        end

        context 'within the grace period' do
          it 'redirects to two-factor configuration page', :freeze_time do
            expect(authentication_metrics)
              .to increment(:user_authenticated_counter)

            gitlab_sign_in(user)

            expect(page).to have_current_path profile_two_factor_auth_path, ignore_query: true
            expect(page).to have_content(
              'The group settings for Group 1 and Group 2 require you to enable '\
              'Two-Factor Authentication for your account. '\
              'You can leave Group 1 and leave Group 2. '\
              'You need to do this '\
              'before '\
              "#{(Time.zone.now + 2.days).strftime('%a, %d %b %Y %H:%M:%S %z')}"
            )
          end

          it 'allows skipping two-factor configuration' do
            expect(authentication_metrics)
              .to increment(:user_authenticated_counter)

            gitlab_sign_in(user)

            expect(page).to have_current_path profile_two_factor_auth_path, ignore_query: true
            click_link _('Configure it later')
            expect(page).to have_current_path root_path, ignore_query: true
          end
        end

        context 'after the grace period' do
          let(:user) { create(:user, otp_grace_period_started_at: 9999.hours.ago) }

          it 'redirects to two-factor configuration page' do
            expect(authentication_metrics)
              .to increment(:user_authenticated_counter)

            gitlab_sign_in(user)

            expect(page).to have_current_path profile_two_factor_auth_path, ignore_query: true
            expect(page).to have_content(
              'The group settings for Group 1 and Group 2 require you to enable ' \
              'Two-Factor Authentication for your account.'
            )
          end

          it 'disallows skipping two-factor configuration' do
            expect(authentication_metrics)
              .to increment(:user_authenticated_counter)

            gitlab_sign_in(user)

            expect(page).to have_current_path profile_two_factor_auth_path, ignore_query: true
            expect(page).not_to have_link(_('Configure it later'))
          end
        end
      end

      context 'without grace period defined' do
        before do
          stub_application_setting(two_factor_grace_period: 0)
        end

        it 'redirects to two-factor configuration page' do
          expect(authentication_metrics)
            .to increment(:user_authenticated_counter)

          gitlab_sign_in(user)

          expect(page).to have_current_path profile_two_factor_auth_path, ignore_query: true
          expect(page).to have_content(
            'The group settings for Group 1 and Group 2 require you to enable ' \
            'Two-Factor Authentication for your account. '\
            'You can leave Group 1 and leave Group 2.'
          )
        end
      end
    end
  end

  describe 'UI tabs and panes' do
    context 'when no defaults are changed' do
      it 'does not render any tabs' do
        visit new_user_session_path

        ensure_no_tabs
      end

      it 'renders logo', :js do
        visit new_user_session_path

        image = find('img.js-portrait-logo-detection')
        expect(image['class']).to include('gl-h-10')
      end

      it 'renders link to sign up path' do
        visit new_user_session_path

        expect(page.body).to have_link('Register now', href: new_user_registration_path)
      end
    end

    context 'when signup is disabled' do
      before do
        stub_application_setting(signup_enabled: false)

        visit new_user_session_path
      end

      it 'does not render any tabs' do
        ensure_no_tabs
      end

      it 'does not render link to sign up path' do
        visit new_user_session_path

        expect(page.body).not_to have_link('Register now', href: new_user_registration_path)
      end
    end

    context 'when ldap is enabled' do
      include LdapHelpers

      let(:provider) { 'ldapmain' }
      let(:ldap_server_config) do
        {
          'label' => 'Main LDAP',
          'provider_name' => provider,
          'attributes' => {},
          'encryption' => 'plain',
          'uid' => 'uid',
          'base' => 'dc=example,dc=com'
        }
      end

      before do
        stub_ldap_setting(enabled: true)
        allow(::Gitlab::Auth::Ldap::Config).to receive_messages(enabled: true, servers: [ldap_server_config])
        allow(Gitlab::Auth::OAuth::Provider).to receive_messages(providers: [provider.to_sym])

        Ldap::OmniauthCallbacksController.define_providers!
        Rails.application.reload_routes!

        allow_next_instance_of(ActionDispatch::Routing::RoutesProxy) do |instance|
          allow(instance).to receive(:"user_#{provider}_omniauth_callback_path")
            .and_return("/users/auth/#{provider}/callback")
        end
      end

      it 'correctly renders tabs and panes' do
        visit new_user_session_path

        ensure_tab_pane_correctness(['Main LDAP', 'Standard'])
      end

      it 'renders link to sign up path' do
        visit new_user_session_path

        expect(page.body).to have_link('Register now', href: new_user_registration_path)
      end

      it 'displays the remember me checkbox' do
        visit new_user_session_path

        ensure_remember_me_in_tab(ldap_server_config['label'])
      end

      context 'when remember me is not enabled' do
        before do
          stub_application_setting(remember_me_enabled: false)
        end

        it 'does not display the remember me checkbox' do
          visit new_user_session_path

          ensure_remember_me_not_in_tab(ldap_server_config['label'])
        end
      end
    end

    context 'when crowd is enabled' do
      before do
        allow(Gitlab::Auth::OAuth::Provider).to receive_messages(providers: [:crowd])
        stub_application_setting(crowd_enabled: true)

        Ldap::OmniauthCallbacksController.define_providers!
        Rails.application.reload_routes!

        allow_next_instance_of(ActionDispatch::Routing::RoutesProxy) do |instance|
          allow(instance).to receive(:user_crowd_omniauth_authorize_path)
            .and_return("/users/auth/crowd/callback")
        end
      end

      it 'correctly renders tabs and panes' do
        visit new_user_session_path

        ensure_tab_pane_correctness(%w[Crowd Standard])
      end

      it 'displays the remember me checkbox' do
        visit new_user_session_path

        ensure_remember_me_in_tab(_('Crowd'))
      end

      context 'when remember me is not enabled' do
        before do
          stub_application_setting(remember_me_enabled: false)
        end

        it 'does not display the remember me checkbox' do
          visit new_user_session_path

          ensure_remember_me_not_in_tab(_('Crowd'))
        end
      end
    end
  end

  describe 'Client helper classes and flags' do
    it 'adds client browser and platform classes to page body' do
      visit root_path
      expect(find('body')[:class]).to include('gl-browser-generic')
      expect(find('body')[:class]).to include('gl-platform-other')
    end
  end

  context 'when terms are enforced', :js do
    let(:user) { create(:user) }

    before do
      enforce_terms
    end

    it 'asks to accept the terms on first login' do
      expect(authentication_metrics)
        .to increment(:user_authenticated_counter)

      visit new_user_session_path

      gitlab_sign_in(user)

      expect_to_be_on_terms_page
      click_button 'Accept terms'

      expect(page).to have_current_path(root_path, ignore_query: true)
      expect(page).not_to have_content(I18n.t('devise.failure.already_authenticated'))
    end

    it 'does not ask for terms when the user already accepted them' do
      expect(authentication_metrics)
        .to increment(:user_authenticated_counter)

      accept_terms(user)

      visit new_user_session_path

      gitlab_sign_in(user)

      expect(page).to have_current_path(root_path, ignore_query: true)
    end

    context 'when 2FA is required for the user' do
      before do
        group = create(:group, require_two_factor_authentication: true)
        group.add_developer(user)
      end

      context 'when the user did not enable 2FA' do
        it 'asks to set 2FA before asking to accept the terms' do
          expect(authentication_metrics)
            .to increment(:user_authenticated_counter)

          visit new_user_session_path

          gitlab_sign_in(user)

          expect_to_be_on_terms_page
          click_button 'Accept terms'

          expect(page).to have_current_path(profile_two_factor_auth_path, ignore_query: true)

          # Use the secret shown on the page to generate the OTP that will be entered.
          # This detects issues wherein a new secret gets generated after the
          # page is shown.
          wait_for_requests

          otp_secret = page.find('.two-factor-secret').text.gsub('Key:', '').delete(' ')
          current_otp = ROTP::TOTP.new(otp_secret).now

          fill_in 'pin_code', with: current_otp
          fill_in 'current_password', with: user.password

          click_button 'Register with two-factor app'
          click_button 'Copy codes'
          click_link 'Proceed'

          expect(page).to have_current_path(profile_account_path, ignore_query: true)
          expect(page).to have_content('You have set up 2FA for your account! If you lose access to your 2FA device, you can use your recovery codes to access your account. Alternatively, if you upload an SSH key, you can use that key to generate additional recovery codes.')
        end
      end

      context 'when the user already enabled 2FA' do
        before do
          user.update!(otp_required_for_login: true, otp_secret: User.generate_otp_secret(32))
        end

        it 'asks the user to accept the terms' do
          expect(authentication_metrics)
            .to increment(:user_authenticated_counter)
            .and increment(:user_two_factor_authenticated_counter)

          visit new_user_session_path

          gitlab_sign_in(user, two_factor_auth: true)

          expect_to_be_on_terms_page
          click_button 'Accept terms'

          expect(page).to have_current_path(root_path, ignore_query: true)
        end
      end
    end

    context 'when the users password is expired' do
      before do
        user.update!(password_expires_at: Time.zone.parse('2018-05-08 11:29:46 UTC'))
      end

      it 'asks the user to accept the terms before setting a new password' do
        expect(authentication_metrics)
          .to increment(:user_authenticated_counter)

        visit new_user_session_path

        gitlab_sign_in(user)

        expect_to_be_on_terms_page
        click_button 'Accept terms'

        expect(page).to have_current_path(new_user_settings_password_path, ignore_query: true)

        new_password = User.random_password

        fill_in 'user_password', with: user.password
        fill_in 'user_new_password', with: new_password
        fill_in 'user_password_confirmation', with: new_password
        click_button 'Update password'

        expect(page).to have_content('Password successfully changed')
      end
    end

    context 'when the user does not have an email configured' do
      let_it_be(:username) { generate(:username) }
      let(:user) { create(:omniauth_user, extern_uid: 'my-uid', provider: 'saml', email: "temp-email-for-oauth-#{username}@gitlab.localhost") }

      before do
        stub_feature_flags(edit_user_profile_vue: false)
        stub_omniauth_saml_config(enabled: true, auto_link_saml_user: true, allow_single_sign_on: ['saml'], providers: [mock_saml_config])
      end

      it 'asks the user to accept the terms before setting an email' do
        expect(authentication_metrics)
        .to increment(:user_authenticated_counter)

        gitlab_sign_in_via('saml', user, 'my-uid')

        expect_to_be_on_terms_page
        click_button 'Accept terms'

        expect(page).to have_current_path(user_settings_profile_path, ignore_query: true)

        # Wait until the form has been initialized
        has_testid?('form-ready')

        fill_in 'Email', with: 'hello@world.com'

        click_button 'Update profile settings'

        expect(page).to have_content('Profile was successfully updated')
        expect(user.reload).to have_attributes({ unconfirmed_email: 'hello@world.com' })
      end
    end
  end

  context 'when sending confirmation email and not yet confirmed' do
    let!(:user) { create(:user, confirmed_at: nil) }
    let(:grace_period) { 2.days }
    let(:alert_title) { 'Please confirm your email address' }
    let(:alert_message) { "To continue, you need to select the link in the confirmation email we sent to verify your email address. If you didn't get our email, select Resend confirmation email" }

    before do
      stub_application_setting_enum('email_confirmation_setting', 'soft')
      allow(User).to receive(:allow_unconfirmed_access_for).and_return grace_period
    end

    it 'allows login and shows a flash warning to confirm the email address' do
      expect(authentication_metrics).to increment(:user_authenticated_counter)

      gitlab_sign_in(user)

      expect(page).to have_current_path root_path, ignore_query: true
      expect(page).to have_content("Please check your email (#{user.email}) to verify that you own this address and unlock the power of CI/CD.")
    end

    context "when not having confirmed within Devise's allow_unconfirmed_access_for time" do
      it 'does not allow login and shows a flash alert to confirm the email address', :js do
        travel_to((grace_period + 1.day).from_now) do
          expect(authentication_metrics)
            .to increment(:user_unauthenticated_counter)
            .and increment(:user_session_destroyed_counter).twice

          gitlab_sign_in(user)

          expect(page).to have_current_path new_user_session_path, ignore_query: true
          expect(page).to have_content(alert_title)
          expect(page).to have_content(alert_message)
          expect(page).to have_link('Resend confirmation email', href: new_user_confirmation_path)
        end
      end
    end
  end

  context 'when signing in with JWT' do
    let_it_be(:user) { create(:user) }

    before do
      stub_omniauth_config(providers: [{ name: 'jwt', label: 'JWT', args: {} }])
      stub_omniauth_provider('jwt')
      mock_auth_hash('jwt', 'jwt_uid', user.email)
    end

    context 'when the user does not have a JWT identity' do
      context 'when the user is already signed in' do
        before do
          expect(authentication_metrics).to increment(:user_authenticated_counter)

          gitlab_sign_in(user)
        end

        it 'requires the user to authorize linking the JWT identity' do
          visit user_jwt_omniauth_callback_path

          expect(page).to have_current_path new_user_settings_identities_path, ignore_query: true
          expect(page).to have_content(
            format(
              s_('Allow %{strongOpen}%{provider}%{strongClose} to sign you in?'),
              strongOpen: '',
              strongClose: '',
              provider: 'JWT')
          )

          click_button 'Authorize'

          expect(page).to have_current_path profile_account_path
          expect(page).to have_content(_('Authentication method updated'))

          expect(user.identities.last.provider).to eq('jwt')
          expect(user.identities.last.extern_uid).to eq('jwt_uid')
        end

        it 'does not link the identity when the user clicks Cancel' do
          visit user_jwt_omniauth_callback_path

          expect(page).to have_current_path new_user_settings_identities_path, ignore_query: true
          expect(page).to have_content(
            format(
              s_('Allow %{strongOpen}%{provider}%{strongClose} to sign you in?'),
              strongOpen: '',
              strongClose: '',
              provider: 'JWT')
          )

          click_link 'Cancel'

          expect(page).to have_current_path profile_account_path
          expect(page).not_to have_content(_('Authentication method updated'))

          expect(user.identities).to be_empty
        end
      end
    end
  end
end
