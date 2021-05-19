# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SessionsController do
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
        it 'redirects to :omniauth_authorize_path' do
          get(:new)

          expect(response).to have_gitlab_http_status(:found)
          expect(response).to redirect_to('/saml')
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

          expect(controller).to set_flash.now[:alert].to(/Invalid login or password/)
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

        it 'creates an audit log record' do
          expect { post(:create, params: { user: user_params }) }.to change { AuditEvent.count }.by(1)
          expect(AuditEvent.last.details[:with]).to eq('standard')
        end

        it 'creates an authentication event record' do
          expect { post(:create, params: { user: user_params }) }.to change { AuthenticationEvent.count }.by(1)
          expect(AuthenticationEvent.last.provider).to eq('standard')
        end

        include_examples 'user login request with unique ip limit', 302 do
          def request
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

      context 'with reCAPTCHA' do
        def unsuccesful_login(user_params, sesion_params: {})
          # Without this, `verify_recaptcha` arbitrarily returns true in test env
          Recaptcha.configuration.skip_verify_env.delete('test')
          counter = double(:counter)

          expect(counter).to receive(:increment)
          expect(Gitlab::Metrics).to receive(:counter)
                                      .with(:failed_login_captcha_total, anything)
                                      .and_return(counter)

          post(:create, params: { user: user_params }, session: sesion_params)
        end

        def succesful_login(user_params, sesion_params: {})
          # Avoid test ordering issue and ensure `verify_recaptcha` returns true
          Recaptcha.configuration.skip_verify_env << 'test'
          counter = double(:counter)

          expect(counter).to receive(:increment)
          expect(Gitlab::Metrics).to receive(:counter)
                                      .with(:successful_login_captcha_total, anything)
                                      .and_return(counter)
          expect(Gitlab::Metrics).to receive(:counter).and_call_original

          post(:create, params: { user: user_params }, session: sesion_params)
        end

        context 'when reCAPTCHA is enabled' do
          let(:user) { create(:user) }
          let(:user_params) { { login: user.username, password: user.password } }

          before do
            stub_application_setting(recaptcha_enabled: true)
            request.headers[described_class::CAPTCHA_HEADER] = '1'
          end

          it 'displays an error when the reCAPTCHA is not solved' do
            # Without this, `verify_recaptcha` arbitrarily returns true in test env

            unsuccesful_login(user_params)

            expect(response).to render_template(:new)
            expect(flash[:alert]).to include 'There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.'
            expect(subject.current_user).to be_nil
          end

          it 'successfully logs in a user when reCAPTCHA is solved' do
            succesful_login(user_params)

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
              unsuccesful_login(user_params, sesion_params: { failed_login_attempts: 6 })

              expect(response).to render_template(:new)
              expect(flash[:alert]).to include 'There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.'
              expect(subject.current_user).to be_nil
            end

            it 'successfully logs in a user when reCAPTCHA is solved' do
              succesful_login(user_params, sesion_params: { failed_login_attempts: 6 })

              expect(subject.current_user).to eq user
            end
          end

          context 'when there are more than 5 anonymous session with the same IP' do
            before do
              allow(Gitlab::AnonymousSession).to receive_message_chain(:new, :session_count).and_return(6)
            end

            it 'displays an error when the reCAPTCHA is not solved' do
              unsuccesful_login(user_params)

              expect(response).to render_template(:new)
              expect(flash[:alert]).to include 'There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.'
              expect(subject.current_user).to be_nil
            end

            it 'successfully logs in a user when reCAPTCHA is solved' do
              expect(Gitlab::AnonymousSession).to receive_message_chain(:new, :cleanup_session_per_ip_count)

              succesful_login(user_params)

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
              authenticate_2fa(login: another_user.username,
                               otp_attempt: another_user.current_otp)

              expect(subject.current_user).not_to eq another_user
            end
          end

          context 'when OTP is invalid for another user' do
            it 'does not authenticate' do
              authenticate_2fa(login: another_user.username,
                               otp_attempt: 'invalid')

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
              before do
                authenticate_2fa(otp_attempt: 'invalid')
              end

              it 'does not authenticate' do
                expect(subject.current_user).not_to eq user
              end

              it 'warns about invalid OTP code' do
                expect(controller).to set_flash.now[:alert]
                  .to(/Invalid two-factor code/)
              end
            end
          end

          context 'when the user is on their last attempt' do
            before do
              user.update(failed_attempts: User.maximum_attempts.pred)
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
    end

    context 'when using two-factor authentication via U2F device' do
      let(:user) { create(:user, :two_factor) }

      def authenticate_2fa_u2f(user_params)
        post(:create, params: { user: user_params }, session: { otp_user_id: user.id })
      end

      before do
        stub_feature_flags(webauthn: false)
      end

      context 'remember_me field' do
        it 'sets a remember_user_token cookie when enabled' do
          allow(U2fRegistration).to receive(:authenticate).and_return(true)
          allow(controller).to receive(:find_user).and_return(user)
          expect(controller)
            .to receive(:remember_me).with(user).and_call_original

          authenticate_2fa_u2f(remember_me: '1', login: user.username, device_response: "{}")

          expect(response.cookies['remember_user_token']).to be_present
        end

        it 'does nothing when disabled' do
          allow(U2fRegistration).to receive(:authenticate).and_return(true)
          allow(controller).to receive(:find_user).and_return(user)
          expect(controller).not_to receive(:remember_me)

          authenticate_2fa_u2f(remember_me: '0', login: user.username, device_response: "{}")

          expect(response.cookies['remember_user_token']).to be_nil
        end
      end

      it "creates an audit log record" do
        allow(U2fRegistration).to receive(:authenticate).and_return(true)
        expect { authenticate_2fa_u2f(login: user.username, device_response: "{}") }.to change { AuditEvent.count }.by(1)
        expect(AuditEvent.last.details[:with]).to eq("two-factor-via-u2f-device")
      end

      it "creates an authentication event record" do
        allow(U2fRegistration).to receive(:authenticate).and_return(true)

        expect { authenticate_2fa_u2f(login: user.username, device_response: "{}") }.to change { AuthenticationEvent.count }.by(1)
        expect(AuthenticationEvent.last.provider).to eq("two-factor-via-u2f-device")
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

  describe '#set_current_context' do
    let_it_be(:user) { create(:user) }

    context 'when signed in' do
      before do
        sign_in(user)
      end

      it 'sets the username and caller_id in the context' do
        expect(controller).to receive(:destroy).and_wrap_original do |m, *args|
          expect(Gitlab::ApplicationContext.current)
            .to include('meta.user' => user.username,
                        'meta.caller_id' => 'SessionsController#destroy')

          m.call(*args)
        end

        delete :destroy
      end
    end

    context 'when not signed in' do
      it 'sets the caller_id in the context' do
        expect(controller).to receive(:new).and_wrap_original do |m, *args|
          expect(Gitlab::ApplicationContext.current)
            .to include('meta.caller_id' => 'SessionsController#new')
          expect(Gitlab::ApplicationContext.current)
            .not_to include('meta.user')

          m.call(*args)
        end

        get :new
      end
    end

    context 'when the user becomes locked' do
      before do
        user.update!(failed_attempts: User.maximum_attempts.pred)
      end

      it 'sets the caller_id in the context' do
        allow_any_instance_of(User).to receive(:lock_access!).and_wrap_original do |m, *args|
          expect(Gitlab::ApplicationContext.current)
            .to include('meta.caller_id' => 'SessionsController#create')
          expect(Gitlab::ApplicationContext.current)
            .not_to include('meta.user')

          m.call(*args)
        end

        post(:create,
             params: { user: { login: user.username, password: user.password.succ } })
      end
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
  end
end
