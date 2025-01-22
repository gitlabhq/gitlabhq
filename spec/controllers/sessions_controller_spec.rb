# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SessionsController, feature_category: :system_access do
  include DeviseHelpers
  include LdapHelpers

  before do
    set_devise_mapping(context: @request)
  end

  describe '#new' do
    context 'when auto sign-in is enabled' do
      before do
        stub_omniauth_setting(auto_sign_in_with_provider: :saml)
        allow(controller).to receive(:omniauth_authorize_path).with(:user, :saml)
          .and_return('/saml')
      end

      context 'and no auto_sign_in param is passed' do
        it 'redirects to :omniauth_authorize_path through an intermediate template' do
          get(:new)

          expect(response).to render_template('devise/sessions/redirect_to_provider', layout: false)
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'and auto_sign_in=false param is passed' do
        it 'responds with 200' do
          get(:new, params: { auto_sign_in: 'false' })

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'with LDAP enabled' do
      before do
        stub_ldap_setting(enabled: true)
      end

      it 'ldap_servers available in helper' do
        get(:new)

        expect(subject.ldap_servers.first.to_h).to include('label' => 'ldap', 'provider_name' => 'ldapmain')
      end

      context 'with sign_in disabled' do
        before do
          stub_ldap_setting(prevent_ldap_sign_in: true)
        end

        it 'no ldap_servers available in helper' do
          get(:new)

          expect(subject.ldap_servers).to eq []
        end
      end
    end

    it "redirects correctly for referer on same host with params" do
      host = "test.host"
      search_path = "/search?search=seed_project"
      request.headers[:HTTP_REFERER] = "http://#{host}#{search_path}"

      get(:new, params: { redirect_to_referer: :yes })

      expect(controller.stored_location_for(:redirect)).to eq(search_path)
    end

    it 'redirects when in_initial_setup_state? is detected' do
      allow(controller).to receive(:in_initial_setup_state?).and_return(true)

      get(:new)

      expect(response).to redirect_to(new_admin_initial_setup_path)
    end

    it_behaves_like "switches to user preferred language", 'Sign in'
  end

  describe '#create' do
    it_behaves_like 'known sign in' do
      let(:user) { create(:user) }
      let(:post_action) { post(:create, params: { user: { login: user.username, password: user.password } }) }
    end

    context 'when using standard authentications' do
      let(:user) { create(:user) }
      let(:post_action) { post(:create, params: { user: { login: user.username, password: user.password } }) }

      context 'invalid password' do
        it 'does not authenticate user' do
          post(:create, params: { user: { login: 'invalid', password: 'invalid' } })

          expect(response).to have_gitlab_http_status(:ok)
          expect(@request.env['warden']).not_to be_authenticated
          expect(controller).to set_flash.now[:alert].to(/Invalid login or password/)
        end
      end

      context 'mass assignment' do
        it 'does not authenticate with multiple usernames' do
          expect do
            post(:create, params: { user: { login: ['invalid', user.username], password: user.password } })
          end.to raise_error(NoMethodError)
          expect(@request.env['warden']).not_to be_authenticated
        end

        it 'does not authenticate with multiple passwords' do
          expect do
            post(:create, params: { user: { login: user.username, password: ['aaaaaa', user.password] } })
          end.to raise_error(NoMethodError)
          expect(@request.env['warden']).not_to be_authenticated
        end

        context 'when parameter sanitization is applied' do
          let(:password) { User.random_password }
          let(:reset_password_token) { user.send_reset_password_instructions }

          let(:malicious_user_hash) do
            {
              user: {
                login: user.username,
                password: password,
                remember_me: '1',
                reset_password_token: user.send_reset_password_instructions,
                admin: true,
                require_two_factor_authentication: false
              }
            }
          end

          let(:sanitized_params) { controller.send(:user_params) }

          it 'returns a hash of only permitted scalar keys', :aggregate_failures do
            put :create, params: malicious_user_hash

            expect(sanitized_params.to_h).to include({
              login: user.username,
              password: password,
              remember_me: '1'
            })

            expect(sanitized_params.to_h).not_to include({
              reset_password_token: user.send_reset_password_instructions,
              admin: true,
              require_two_factor_authentication: false
            })
          end
        end
      end

      context 'when user with LDAP identity' do
        before do
          create(:identity, provider: 'ldapmain', user: user)
        end

        it 'does not authenticate user' do
          post_action

          expect(response).to have_gitlab_http_status(:ok)
          expect(@request.env['warden']).not_to be_authenticated
          expect(flash[:alert]).to include(I18n.t('devise.failure.invalid'))
        end
      end

      context 'a blocked user' do
        it 'does not authenticate the user' do
          user.block!
          post_action

          expect(@request.env['warden']).not_to be_authenticated
          expect(flash[:alert]).to include('Your account has been blocked')
        end
      end

      context 'a `blocked pending approval` user' do
        it 'does not authenticate the user' do
          user.block_pending_approval!
          post_action

          expect(@request.env['warden']).not_to be_authenticated
          expect(flash[:alert]).to include('Your account is pending approval from your GitLab administrator and hence blocked')
        end
      end

      context 'an internal user' do
        it 'does not authenticate the user' do
          user.ghost!
          post_action

          expect(@request.env['warden']).not_to be_authenticated
          expect(flash[:alert]).to include('Your account does not have the required permission to login')
        end
      end

      context 'when using valid password', :clean_gitlab_redis_shared_state do
        let(:user) { create(:user) }
        let(:user_params) { { login: user.username, password: user.password } }

        it 'authenticates user correctly' do
          post(:create, params: { user: user_params })

          expect(subject.current_user).to eq user
        end

        context 'a deactivated user' do
          before do
            user.deactivate!
            post(:create, params: { user: user_params })
          end

          it 'is allowed to login' do
            expect(subject.current_user).to eq user
          end

          it 'activates the user' do
            expect(subject.current_user.active?).to be_truthy
          end

          it 'shows reactivation flash message after logging in' do
            expect(flash[:notice]).to eq('Welcome back! Your account had been deactivated due to inactivity but is now reactivated.')
          end
        end

        context 'with password authentication disabled' do
          before do
            stub_application_setting(password_authentication_enabled_for_web: false)
          end

          it 'does not sign in the user' do
            post(:create, params: { user: user_params })

            expect(@request.env['warden']).not_to be_authenticated
            expect(subject.current_user).to be_nil
          end

          it 'returns status 403' do
            post(:create, params: { user: user_params })

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end

        context 'when password authentication is disabled for SSO users' do
          let_it_be(:user) { create(:omniauth_user, password_automatically_set: false) }

          before do
            stub_application_setting(disable_password_authentication_for_users_with_sso_identities: true)
          end

          it 'does not authenticate the user' do
            post(:create, params: { user: user_params })

            expect(response).to have_gitlab_http_status(:ok)
            expect(@request.env['warden']).not_to be_authenticated
            expect(flash[:alert]).to include(I18n.t('devise.failure.invalid'))
          end
        end

        it 'creates an audit log record' do
          expect { post(:create, params: { user: user_params }) }.to change { AuditEvent.count }.by(1)
          expect(AuditEvent.last.details[:with]).to eq('standard')
        end

        it 'creates an authentication event record' do
          expect { post(:create, params: { user: user_params }) }.to change { AuthenticationEvent.count }.by(1)
          expect(AuthenticationEvent.last.provider).to eq('standard')
        end

        include_examples 'user login request with unique ip limit', 302 do
          def gitlab_request
            post(:create, params: { user: user_params })
            expect(subject.current_user).to eq user
            subject.sign_out user
          end
        end

        it 'updates the user activity' do
          expect do
            post(:create, params: { user: user_params })
          end.to change { user.reload.last_activity_on }.to(Date.today)
        end
      end

      context 'when user has dismissed broadcast_messages' do
        let_it_be(:user) { create(:user) }
        let_it_be(:message_banner) { create(:broadcast_message, broadcast_type: :banner, message: 'banner') }
        let_it_be(:message_notification) { create(:broadcast_message, broadcast_type: :notification, message: 'notification') }
        let_it_be(:other_message) { create(:broadcast_message, broadcast_type: :banner, message: 'other') }

        before_all do
          create(:broadcast_message_dismissal, broadcast_message: message_banner, user: user)
          create(:broadcast_message_dismissal, broadcast_message: message_notification, user: user)
          create(:broadcast_message_dismissal, broadcast_message: other_message, user: build(:user))
        end

        it 'creates dismissed cookies based on db records' do
          expect(cookies["hide_broadcast_message_#{message_banner.id}"]).to be_nil
          expect(cookies["hide_broadcast_message_#{message_notification.id}"]).to be_nil
          expect(cookies["hide_broadcast_message_#{other_message.id}"]).to be_nil

          post_action

          expect(cookies["hide_broadcast_message_#{message_banner.id}"]).to be(true)
          expect(cookies["hide_broadcast_message_#{message_notification.id}"]).to be(true)
          expect(cookies["hide_broadcast_message_#{other_message.id}"]).to be_nil
        end

        context 'when dismissal is expired' do
          let_it_be(:message) { create(:broadcast_message, broadcast_type: :banner, message: 'banner') }

          before do
            create(:broadcast_message_dismissal, :expired, broadcast_message: message, user: user)
          end

          it 'does not create cookie' do
            expect(cookies["hide_broadcast_message_#{message.id}"]).to be_nil

            post_action

            expect(cookies["hide_broadcast_message_#{message.id}"]).to be_nil
          end
        end
      end

      context 'with reCAPTCHA' do
        def unsuccessful_login(user_params, sesion_params: {})
          # Without this, `verify_recaptcha` arbitrarily returns true in test env
          Recaptcha.configuration.skip_verify_env.delete('test')
          counter = double(:counter)

          expect(counter).to receive(:increment)
          expect(Gitlab::Metrics).to receive(:counter)
                                      .with(:failed_login_captcha_total, anything)
                                      .and_return(counter)

          post(:create, params: { user: user_params }, session: sesion_params)
        end

        def successful_login(user_params, sesion_params: {})
          # Avoid test ordering issue and ensure `verify_recaptcha` returns true
          Recaptcha.configuration.skip_verify_env << 'test'
          counter = double(:counter)

          expect(counter).to receive(:increment)
          expect(Gitlab::Metrics).to receive(:counter)
                                      .with(:successful_login_captcha_total, anything)
                                      .and_return(counter)
          expect(Gitlab::Metrics).to receive(:counter).at_least(1).time.and_call_original

          post(:create, params: { user: user_params }, session: sesion_params)
        end

        context 'when reCAPTCHA is enabled' do
          let(:user) { create(:user) }
          let(:user_params) { { login: user.username, password: user.password } }

          before do
            stub_application_setting(recaptcha_enabled: true)
            request.headers[described_class::CAPTCHA_HEADER] = '1'
          end

          context 'when the reCAPTCHA is not solved' do
            it 'displays an error' do
              unsuccessful_login(user_params)

              expect(response).to render_template(:new)
              expect(flash[:alert]).to include _('There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.')
              expect(subject.current_user).to be_nil
            end

            it 'sets gon variables' do
              Gon.clear

              unsuccessful_login(user_params)

              expect(response).to render_template(:new)
              expect(Gon.all_variables).not_to be_empty
            end
          end

          it 'successfully logs in a user when reCAPTCHA is solved' do
            successful_login(user_params)

            expect(subject.current_user).to eq user
          end
        end

        context 'when reCAPTCHA login protection is enabled' do
          let(:user) { create(:user) }
          let(:user_params) { { login: user.username, password: user.password } }

          before do
            stub_application_setting(login_recaptcha_protection_enabled: true)
          end

          context 'when user tried to login 5 times' do
            it 'displays an error when the reCAPTCHA is not solved' do
              unsuccessful_login(user_params, sesion_params: { failed_login_attempts: 6 })

              expect(response).to render_template(:new)
              expect(flash[:alert]).to include _('There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.')
              expect(subject.current_user).to be_nil
            end

            it 'successfully logs in a user when reCAPTCHA is solved' do
              successful_login(user_params, sesion_params: { failed_login_attempts: 6 })

              expect(subject.current_user).to eq user
            end
          end

          context 'when there are more than 5 anonymous session with the same IP' do
            before do
              allow(Gitlab::AnonymousSession).to receive_message_chain(:new, :session_count).and_return(6)
            end

            it 'displays an error when the reCAPTCHA is not solved' do
              unsuccessful_login(user_params)

              expect(response).to render_template(:new)
              expect(flash[:alert]).to include _('There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.')
              expect(subject.current_user).to be_nil
            end

            it 'successfully logs in a user when reCAPTCHA is solved' do
              expect(Gitlab::AnonymousSession).to receive_message_chain(:new, :cleanup_session_per_ip_count)

              successful_login(user_params)

              expect(subject.current_user).to eq user
            end
          end
        end
      end
    end

    context 'when using two-factor authentication via OTP' do
      let(:user) { create(:user, :two_factor) }

      def authenticate_2fa(otp_user_id: user.id, **user_params)
        post(:create, params: { user: user_params }, session: { otp_user_id: otp_user_id })
      end

      context 'remember_me field' do
        it 'sets a remember_user_token cookie when enabled' do
          allow(controller).to receive(:find_user).and_return(user)
          expect(controller)
            .to receive(:remember_me).with(user).and_call_original

          authenticate_2fa(remember_me: '1', otp_attempt: user.current_otp)

          expect(response.cookies['remember_user_token']).to be_present
        end

        it 'does nothing when disabled' do
          allow(controller).to receive(:find_user).and_return(user)
          expect(controller).not_to receive(:remember_me)

          authenticate_2fa(remember_me: '0', otp_attempt: user.current_otp)

          expect(response.cookies['remember_user_token']).to be_nil
        end
      end

      context 'with password authentication disabled' do
        before do
          stub_application_setting(password_authentication_enabled_for_web: false)
        end

        it 'allows 2FA stage of non-password login' do
          authenticate_2fa(otp_attempt: user.current_otp)

          expect(@request.env['warden']).to be_authenticated
          expect(subject.current_user).to eq user
        end
      end

      # See issue gitlab-org/gitlab#20302.
      context 'when otp_user_id is stale' do
        render_views

        it 'favors login over otp_user_id when password is present and does not authenticate the user' do
          authenticate_2fa(
            login: 'random_username',
            password: user.password,
            otp_user_id: user.id
          )

          expect(controller).to set_flash.now[:alert].to(/Invalid login or password/)
        end
      end

      ##
      # See issue gitlab-org/gitlab-foss#14900
      #
      context 'when authenticating with login and OTP of another user' do
        context 'when another user has 2FA enabled' do
          let(:another_user) { create(:user, :two_factor) }

          context 'when OTP is valid for another user' do
            it 'does not authenticate' do
              authenticate_2fa(login: another_user.username, otp_attempt: another_user.current_otp)

              expect(subject.current_user).not_to eq another_user
            end
          end

          context 'when OTP is invalid for another user' do
            it 'does not authenticate' do
              authenticate_2fa(login: another_user.username, otp_attempt: 'invalid')

              expect(subject.current_user).not_to eq another_user
            end
          end

          context 'when authenticating with OTP' do
            context 'when OTP is valid' do
              it 'authenticates correctly' do
                authenticate_2fa(otp_attempt: user.current_otp)

                expect(subject.current_user).to eq user
              end
            end

            context 'when OTP is invalid' do
              let(:code) { 'invalid' }

              it 'does not authenticate' do
                authenticate_2fa(otp_attempt: code)

                expect(subject.current_user).not_to eq user
              end

              it 'warns about invalid OTP code' do
                authenticate_2fa(otp_attempt: code)

                expect(controller).to set_flash.now[:alert]
                  .to(/Invalid two-factor code/)
              end

              it 'sends an email to the user informing about the attempt to sign in with a wrong OTP code' do
                controller.request.remote_addr = '1.2.3.4'

                expect_next_instance_of(NotificationService) do |instance|
                  expect(instance).to receive(:two_factor_otp_attempt_failed).with(user, '1.2.3.4')
                end

                authenticate_2fa(otp_attempt: code)
              end
            end

            context 'when OTP is an array' do
              let(:code) { %w[000000 000001] }

              it 'does not authenticate' do
                authenticate_2fa(otp_attempt: code)

                expect(subject.current_user).not_to eq user
              end
            end
          end

          context 'when the user is on their last attempt' do
            before do
              user.update!(failed_attempts: User.maximum_attempts.pred)
            end

            context 'when OTP is valid' do
              it 'authenticates correctly' do
                authenticate_2fa(otp_attempt: user.current_otp)

                expect(subject.current_user).to eq user
              end
            end

            context 'when OTP is invalid' do
              before do
                authenticate_2fa(otp_attempt: 'invalid')
              end

              it 'does not authenticate' do
                expect(subject.current_user).not_to eq user
              end

              it 'warns about invalid login' do
                expect(flash[:alert]).to eq('Your account is locked.')
              end

              it 'locks the user' do
                expect(user.reload).to be_access_locked
              end

              it 'keeps the user locked on future login attempts' do
                post(:create, params: { user: { login: user.username, password: user.password } })

                expect(flash[:alert]).to eq('Your account is locked.')
              end
            end
          end
        end
      end

      it "creates an audit log record" do
        expect { authenticate_2fa(login: user.username, otp_attempt: user.current_otp) }.to change { AuditEvent.count }.by(1)
        expect(AuditEvent.last.details[:with]).to eq("two-factor")
      end

      it "creates an authentication event record" do
        expect { authenticate_2fa(login: user.username, otp_attempt: user.current_otp) }.to change { AuthenticationEvent.count }.by(1)
        expect(AuthenticationEvent.last.provider).to eq("two-factor")
      end

      context 'when rendering devise two factor' do
        render_views

        before do
          Gon.clear
        end

        it "adds gon variables" do
          authenticate_2fa(login: user.username, password: user.password)

          expect(response).to render_template('devise/sessions/two_factor')
          expect(Gon.all_variables).not_to be_empty
          expect(response.body).to match('gon.api_version')
        end
      end
    end

    context 'when using two-factor authentication via WebAuthn device' do
      let(:user) { create(:user, :two_factor_via_webauthn) }

      def authenticate_2fa(user_params)
        post(:create, params: { user: user_params }, session: { otp_user_id: user.id })
      end

      context 'remember_me field' do
        it 'sets a remember_user_token cookie when enabled' do
          allow_any_instance_of(Webauthn::AuthenticateService).to receive(:execute).and_return(true)
          allow(controller).to receive(:find_user).and_return(user)
          expect(controller).to receive(:remember_me).with(user).and_call_original

          authenticate_2fa(remember_me: '1', login: user.username, device_response: "{}")

          expect(response.cookies['remember_user_token']).to be_present
        end

        it 'does nothing when disabled' do
          allow_any_instance_of(Webauthn::AuthenticateService).to receive(:execute).and_return(true)
          allow(controller).to receive(:find_user).and_return(user)
          expect(controller).not_to receive(:remember_me)

          authenticate_2fa(remember_me: '0', login: user.username, device_response: "{}")

          expect(response.cookies['remember_user_token']).to be_nil
        end
      end

      it "creates an audit log record" do
        allow_any_instance_of(Webauthn::AuthenticateService).to receive(:execute).and_return(true)

        expect { authenticate_2fa(login: user.username, device_response: "{}") }.to(
          change { AuditEvent.count }.by(1))
        expect(AuditEvent.last.details[:with]).to eq("two-factor-via-webauthn-device")
      end

      it "creates an authentication event record" do
        allow_any_instance_of(Webauthn::AuthenticateService).to receive(:execute).and_return(true)

        expect { authenticate_2fa(login: user.username, device_response: "{}") }.to(
          change { AuthenticationEvent.count }.by(1))
        expect(AuthenticationEvent.last.provider).to eq("two-factor-via-webauthn-device")
      end
    end

    context 'when the user is locked and submits a valid verification token' do
      let(:user) { create(:user) }
      let(:user_params) { { verification_token: 'token' } }
      let(:session_params) { { verification_user_id: user.id } }
      let(:post_action) { post(:create, params: { user: user_params }, session: session_params) }

      before do
        encrypted_token = Devise.token_generator.digest(User, user.email, 'token')
        user.update!(locked_at: Time.current, unlock_token: encrypted_token)
      end

      it_behaves_like 'known sign in'

      it 'successfully logs in a user' do
        post_action

        expect(subject.current_user).to eq user
      end

      context 'when the verification token is invalid' do
        let(:user_params) { { verification_token: 'not-the-token' } }

        it 'does not log the user in' do
          post_action

          expect(subject.current_user).to eq nil
        end
      end

      context 'when the verification token is an array' do
        let(:user_params) { { verification_token: %w[not-the-token still-not-the-token] } }

        it 'does not log the user in' do
          post_action

          expect(subject.current_user).to eq nil
        end
      end
    end
  end

  context 'when login fails' do
    before do
      @request.env["warden.options"] = { action:  'unauthenticated' }
    end

    it 'does increment failed login counts for session' do
      get(:new, params: { user: { login: 'failed' } })

      expect(session[:failed_login_attempts]).to eq(1)
    end
  end

  describe '#destroy' do
    before do
      sign_in(user)
    end

    context 'for a user whose password has expired' do
      let(:user) { create(:user, password_expires_at: 2.days.ago) }

      it 'allows to sign out successfully' do
        delete :destroy

        expect(response).to redirect_to(new_user_session_path)
        expect(controller.current_user).to be_nil
      end
    end

    context 'clearing browser data' do
      let(:user) { create(:user) }

      before do
        cookies[:test_cookie] = 'test-value'
        cookies.encrypted[:test_encrypted_cookie] = 'test-value'
        cookies.signed[:test_signed_cookie] = 'test-value'
        cookies[:current_signin_tab] = 'preserved'
        cookies[:preferred_language] = 'preserved'
      end

      it 'preserve some cookies and clear the rest of cookies known by Rails' do
        delete :destroy

        %w[test_cookie test_encrypted_cookie test_signed_cookie].each do |key|
          expect(response.cookies).to have_key(key)
          expect(response.cookies[key]).to be_nil
        end

        %w[current_signin_tab preferred_language].each do |key|
          expect(response.cookies).not_to have_key(key)
        end
      end

      it 'sends Clear-Site-Data header for all non-cookie data' do
        delete :destroy

        expect(response.headers['Clear-Site-Data']).to eq('"cache", "storage", "executionContexts", "clientHints"')
      end
    end
  end
end
