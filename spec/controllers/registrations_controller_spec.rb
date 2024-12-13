# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RegistrationsController, :with_current_organization, feature_category: :user_profile do
  include TermsHelper
  include FullNameHelper

  before do
    stub_application_setting(require_admin_approval_after_user_signup: false)
  end

  describe '#new' do
    subject(:new) { get :new }

    it 'renders new template and sets the resource variable' do
      expect(new).to render_template(:new)
      expect(response).to have_gitlab_http_status(:ok)
      expect(assigns(:resource)).to be_a(User)
    end

    it_behaves_like "switches to user preferred language", 'Sign up'

    render_views

    it 'has the expected registration url' do
      new

      expect(response.body).to include("action=\"#{user_registration_path}\"")
    end
  end

  describe '#create' do
    before do
      allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(false)
    end

    let_it_be(:base_user_params) do
      { first_name: 'first', last_name: 'last', username: 'new_username', email: 'new@user.com', password: User.random_password }
    end

    let_it_be(:user_params) { { user: base_user_params } }

    let(:session_params) { {} }

    subject(:post_create) { post(:create, params: user_params, session: session_params) }

    context 'with `blocked_pending_approval` state' do
      context 'when the `require_admin_approval_after_user_signup` setting is turned on' do
        before do
          stub_application_setting(require_admin_approval_after_user_signup: true)
        end

        it 'signs up the user in `blocked_pending_approval` state' do
          subject
          created_user = User.find_by(email: 'new@user.com')

          expect(created_user).to be_present
          expect(created_user.blocked_pending_approval?).to eq(true)
        end

        it 'does not log in the user after sign up' do
          subject

          expect(controller.current_user).to be_nil
        end

        it 'shows flash message after signing up' do
          subject

          expect(response).to redirect_to(new_user_session_path(anchor: 'login-pane'))
          expect(flash[:notice])
            .to eq('You have signed up successfully. However, we could not sign you in because your account is awaiting approval from your GitLab administrator.')
        end

        it 'emails the access request to approvers' do
          expect_next_instance_of(NotificationService) do |notification|
            allow(notification).to receive(:new_instance_access_request).with(User.find_by(email: 'new@user.com'))
          end

          subject
        end

        context 'for email confirmation' do
          context 'when email confirmation setting is set to `hard`' do
            before do
              stub_application_setting_enum('email_confirmation_setting', 'hard')
            end

            it 'does not send a confirmation email' do
              expect { subject }
                .not_to have_enqueued_mail(DeviseMailer, :confirmation_instructions)
            end
          end
        end

        context 'with audit events' do
          context 'when not licensed' do
            before do
              stub_licensed_features(admin_audit_log: false)
            end

            it 'does not log any audit event' do
              expect { subject }.not_to change(AuditEvent, :count)
            end
          end
        end
      end

      context 'when the `require_admin_approval_after_user_signup` setting is turned off' do
        it 'signs up the user in `active` state' do
          subject
          created_user = User.find_by(email: 'new@user.com')

          expect(created_user).to be_present
          expect(created_user.active?).to eq(true)
        end

        it 'does not show any flash message after signing up' do
          subject

          expect(flash[:notice]).to be_nil
        end

        it 'does not email the approvers' do
          expect(NotificationService).not_to receive(:new)

          subject
        end

        context 'with email confirmation' do
          context 'when email confirmation setting is set to `hard`' do
            before do
              stub_application_setting_enum('email_confirmation_setting', 'hard')
            end

            it 'sends a confirmation email' do
              expect { subject }
                .to have_enqueued_mail(DeviseMailer, :confirmation_instructions)
            end
          end
        end
      end
    end

    context 'with private profile' do
      context 'when the `user_defaults_to_private_profile` setting is turned on' do
        before do
          stub_application_setting(user_defaults_to_private_profile: true)
        end

        it 'creates new user with profile set to private' do
          subject
          user = User.find_by(email: base_user_params[:email], private_profile: true)

          expect(user).to be_present
        end
      end
    end

    context 'with email confirmation' do
      context 'when email confirmation setting is set to `off`' do
        it 'signs the user in' do
          stub_application_setting_enum('email_confirmation_setting', 'off')

          expect { subject }.not_to have_enqueued_mail(DeviseMailer, :confirmation_instructions)
          expect(controller.current_user).not_to be_nil
        end
      end

      context 'when email confirmation setting is set to `hard`' do
        before do
          stub_application_setting_enum('email_confirmation_setting', 'hard')
          allow(User).to receive(:allow_unconfirmed_access_for).and_return 0
        end

        it 'does not authenticate the user and sends a confirmation email' do
          expect { subject }.to have_enqueued_mail(DeviseMailer, :confirmation_instructions)
          expect(controller.current_user).to be_nil
        end

        it 'tracks an almost there redirect' do
          post_create

          expect_snowplow_event(
            category: described_class.name,
            action: 'render',
            user: User.find_by(email: base_user_params[:email])
          )
        end

        context 'when registration is triggered from an accepted invite' do
          context 'when it is part from the initial invite email', :snowplow do
            let_it_be(:member) { create(:project_member, :invited, invite_email: user_params.dig(:user, :email)) }

            let(:originating_member_id) { member.id }
            let(:session_params) do
              {
                invite_email: user_params.dig(:user, :email),
                originating_member_id: originating_member_id
              }
            end

            context 'when member exists from the session key value' do
              it 'tracks the invite acceptance' do
                post_create

                expect_snowplow_event(
                  category: 'RegistrationsController',
                  action: 'accepted',
                  label: 'invite_email',
                  user: member.reload.user
                )
              end
            end

            context 'when member does not exist from the session key value' do
              let(:originating_member_id) { nil }

              it 'does not track invite acceptance' do
                subject

                expect_no_snowplow_event(
                  category: 'RegistrationsController',
                  action: 'accepted',
                  label: 'invite_email'
                )
              end
            end
          end

          context 'when invite email matches email used on registration' do
            let(:session_params) { { invite_email: user_params.dig(:user, :email) } }

            it 'signs the user in without sending a confirmation email', :aggregate_failures do
              expect { subject }.not_to have_enqueued_mail(DeviseMailer, :confirmation_instructions)
              expect(controller.current_user).to be_confirmed
            end
          end

          context 'when invite email does not match the email used on registration' do
            let(:session_params) { { invite_email: 'bogus@email.com' } }

            it 'does not authenticate the user and sends a confirmation email', :aggregate_failures do
              expect { subject }.to have_enqueued_mail(DeviseMailer, :confirmation_instructions)
              expect(controller.current_user).to be_nil
            end
          end
        end

        context 'when the registration fails' do
          let_it_be(:member) { create(:project_member, :invited) }
          let_it_be(:missing_user_params) do
            { username: '', email: member.invite_email, password: User.random_password }
          end

          let_it_be(:user_params) { { user: missing_user_params } }

          let(:session_params) { { invite_email: member.invite_email } }

          subject { post(:create, params: user_params, session: session_params) }

          it 'does not delete the invitation or register the new user' do
            subject

            expect(member.invite_token).not_to be_nil
            expect(controller.current_user).to be_nil
          end
        end
      end

      context 'when email confirmation setting is set to `soft`' do
        before do
          stub_application_setting_enum('email_confirmation_setting', 'soft')
          allow(User).to receive(:allow_unconfirmed_access_for).and_return 2.days
        end

        it 'authenticates the user and sends a confirmation email' do
          expect { subject }.to have_enqueued_mail(DeviseMailer, :confirmation_instructions)
          expect(controller.current_user).to be_present
          expect(response).to redirect_to(dashboard_projects_path)
        end

        it 'does not track an almost there redirect' do
          post_create

          expect_no_snowplow_event(
            category: described_class.name,
            action: 'render',
            user: User.find_by(email: base_user_params[:email])
          )
        end

        it_behaves_like Onboarding::Redirectable do
          let(:email) { user_params.dig(:user, :email) }
          let(:session_params) { { invite_email: email } }
        end

        context 'when invite email matches email used on registration' do
          let(:session_params) { { invite_email: user_params.dig(:user, :email) } }

          it 'signs the user in without sending a confirmation email', :aggregate_failures do
            expect { subject }.not_to have_enqueued_mail(DeviseMailer, :confirmation_instructions)
            expect(controller.current_user).to be_confirmed
          end
        end

        context 'when invite email does not match the email used on registration' do
          let(:session_params) { { invite_email: 'bogus@email.com' } }

          it 'authenticates the user and sends a confirmation email without confirming', :aggregate_failures do
            expect { subject }.to have_enqueued_mail(DeviseMailer, :confirmation_instructions)
            expect(controller.current_user).not_to be_confirmed
          end
        end
      end

      context 'when signup_enabled? is false' do
        it 'redirects to sign_in' do
          stub_application_setting(signup_enabled: false)

          expect { subject }.not_to change(User, :count)
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context 'when reCAPTCHA is enabled' do
      before do
        stub_application_setting(recaptcha_enabled: true)
      end

      after do
        # Avoid test ordering issue and ensure `verify_recaptcha` returns true
        unless Recaptcha.configuration.skip_verify_env.include?('test')
          Recaptcha.configuration.skip_verify_env << 'test'
        end
      end

      context 'when the reCAPTCHA is not solved' do
        before do
          allow_any_instance_of(described_class).to receive(:verify_recaptcha).and_return(false)
        end

        it 'displays an error' do
          subject

          expect(response).to render_template(:new)
          expect(flash[:alert]).to eq(_('There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.'))
        end

        it 'sets gon variables' do
          Gon.clear

          subject

          expect(response).to render_template(:new)
          expect(Gon.all_variables).not_to be_empty
        end
      end

      it 'redirects to the dashboard projects page when the reCAPTCHA is solved' do
        subject

        expect(response).to redirect_to(dashboard_projects_path)
      end
    end

    context 'when invisible captcha is enabled' do
      before do
        stub_application_setting(invisible_captcha_enabled: true)
        InvisibleCaptcha.timestamp_threshold = treshold
      end

      let(:treshold) { 4 }
      let(:session_params) { { invisible_captcha_timestamp: form_rendered_time.iso8601 } }
      let(:form_rendered_time) { Time.current }
      let(:submit_time) { form_rendered_time + treshold }
      let(:auth_log_attributes) do
        {
          message: auth_log_message,
          env: :invisible_captcha_signup_bot_detected,
          remote_ip: '0.0.0.0',
          request_method: 'POST',
          path: '/users'
        }
      end

      describe 'the honeypot has not been filled and the signup form has not been submitted too quickly' do
        it 'creates an account' do
          travel_to(submit_time) do
            expect { post(:create, params: user_params, session: session_params) }.to change(User, :count).by(1)
          end
        end
      end

      describe 'honeypot spam detection' do
        let(:user_params) { super().merge(firstname: 'Roy', lastname: 'Batty') }
        let(:auth_log_message) { 'Invisible_Captcha_Honeypot_Request' }

        it 'logs the request, refuses to create an account and renders an empty body' do
          travel_to(submit_time) do
            expect(Gitlab::Metrics).to receive(:counter)
              .with(:bot_blocked_by_invisible_captcha_honeypot, 'Counter of blocked sign up attempts with filled honeypot')
              .and_call_original
            expect(Gitlab::AuthLogger).to receive(:error).with(auth_log_attributes).once
            expect { post(:create, params: user_params, session: session_params) }.not_to change(User, :count)
            expect(response).to have_gitlab_http_status(:ok)
            expect(response.body).to be_empty
          end
        end
      end

      describe 'timestamp spam detection' do
        let(:auth_log_message) { 'Invisible_Captcha_Timestamp_Request' }

        context 'when the sign up form has been submitted without the invisible_captcha_timestamp parameter' do
          let(:session_params) { nil }

          it 'logs the request, refuses to create an account and displays a flash alert' do
            travel_to(submit_time) do
              expect(Gitlab::Metrics).to receive(:counter)
                .with(:bot_blocked_by_invisible_captcha_timestamp, 'Counter of blocked sign up attempts with invalid timestamp')
                .and_call_original
              expect(Gitlab::AuthLogger).to receive(:error).with(auth_log_attributes).once
              expect { post(:create, params: user_params, session: session_params) }.not_to change(User, :count)
              expect(response).to redirect_to(new_user_session_path)
              expect(flash[:alert]).to eq(I18n.t('invisible_captcha.timestamp_error_message'))
            end
          end
        end

        context 'when the sign up form has been submitted too quickly' do
          let(:submit_time) { form_rendered_time }

          it 'logs the request, refuses to create an account and displays a flash alert' do
            travel_to(submit_time) do
              expect(Gitlab::Metrics).to receive(:counter)
                .with(:bot_blocked_by_invisible_captcha_timestamp, 'Counter of blocked sign up attempts with invalid timestamp')
                .and_call_original
              expect(Gitlab::AuthLogger).to receive(:error).with(auth_log_attributes).once
              expect { post(:create, params: user_params, session: session_params) }.not_to change(User, :count)
              expect(response).to redirect_to(new_user_session_path)
              expect(flash[:alert]).to eq(I18n.t('invisible_captcha.timestamp_error_message'))
            end
          end
        end
      end
    end

    context 'with terms of service' do
      context 'when terms are enforced' do
        before do
          enforce_terms
        end

        it 'creates the user with accepted terms' do
          subject

          expect(controller.current_user).to be_present
          expect(controller.current_user.terms_accepted?).to be(true)
        end
      end

      context 'when terms are not enforced' do
        it 'creates the user without accepted terms' do
          subject

          expect(controller.current_user).to be_present
          expect(controller.current_user.terms_accepted?).to be(false)
        end
      end
    end

    context 'for system hooks' do
      it 'executes user_create system hook' do
        expect_next_instance_of(SystemHooksService) do |system_hook_service|
          expect(system_hook_service).to receive(:execute_hooks_for).with(User.find_by(email: 'new@user.com'), :create)
        end

        expect { post_create }.to change { User.where(email: 'new@user.com').count }.from(0).to(1)
      end
    end

    context 'when the rate limit has been reached' do
      it 'returns status 429 Too Many Requests', :aggregate_failures do
        ip = '1.2.3.4'
        expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(:user_sign_up, scope: ip).and_return(true)

        controller.request.env['REMOTE_ADDR'] = ip
        post(:create, params: user_params, session: session_params)

        expect(response).to have_gitlab_http_status(:too_many_requests)
      end
    end

    it "logs a 'User Created' message" do
      allow(Gitlab::AppLogger).to receive(:info)

      expect(Gitlab::AppLogger).to receive(:info).with(/\AUser Created: username=new_username email=new@user.com.+\z/).and_call_original

      subject
    end

    it 'handles when params are new_user' do
      post(:create, params: { new_user: base_user_params })

      expect(controller.current_user).not_to be_nil
    end

    it 'sets name from first and last name' do
      post :create, params: { new_user: base_user_params }

      expect(User.last.first_name).to eq(base_user_params[:first_name])
      expect(User.last.last_name).to eq(base_user_params[:last_name])
      expect(User.last.name).to eq full_name(base_user_params[:first_name], base_user_params[:last_name])
    end

    context 'when the password is weak' do
      render_views
      let_it_be(:new_user_params) { { new_user: base_user_params.merge({ password: "password" }) } }

      subject(:post_create) { post(:create, params: new_user_params) }

      it 'renders the form with errors' do
        expect { post_create }.not_to change(User, :count)

        expect(controller.current_user).to be_nil
        expect(response).to render_template(:new)
        expect(response.body).to include(_('Password must not contain commonly used combinations of words and letters'))
      end

      it 'tracks a weak password error' do
        post_create

        expect_snowplow_event(
          category: 'Gitlab::Tracking::Helpers::WeakPasswordErrorEvent',
          action: 'track_weak_password_error',
          controller: 'RegistrationsController',
          method: 'create'
        )
      end
    end

    context 'when the password is not weak' do
      it 'does not track a weak password error' do
        post_create

        expect_no_snowplow_event(
          category: 'Gitlab::Tracking::Helpers::WeakPasswordErrorEvent',
          action: 'track_weak_password_error'
        )
      end
    end

    context 'with preferred language' do
      let(:user_preferred_language) { nil }

      before do
        cookies['preferred_language'] = user_preferred_language

        post :create, params: { new_user: base_user_params }
      end

      subject { User.last.preferred_language }

      context 'with default behavior' do
        it 'sets preferred language to default' do
          is_expected.to eq(Gitlab::CurrentSettings.default_preferred_language)
        end
      end

      context 'when user sets preferred language' do
        let(:user_preferred_language) { 'zh_CN' }

        it 'sets name from first and last name' do
          is_expected.to eq(user_preferred_language)
        end
      end
    end

    context 'when the first or last name is not "present?"' do
      using RSpec::Parameterized::TableSyntax

      render_views

      shared_examples 'a user without present first name or last name' do
        it 'renders the form with errors' do
          subject
          expect(controller.current_user).to be_nil
          expect(response).to render_template(:new)
          expect(response.body).to include(_('name cannot be blank')) # include 'First name' or 'Last name' or both
        end
      end

      where(:first_name, :last_name) do
        nil     | 'last'
        ''      | 'last'
        '   '   | 'last'
        'first' | nil
        'first' | ''
        'first' | '   '
        ''      | ''
      end

      with_them do
        before do
          base_user_params.merge!({ first_name: first_name, last_name: last_name })
        end

        it_behaves_like 'a user without present first name or last name'
      end
    end
  end

  describe '#destroy' do
    let(:user) { create(:user) }

    before do
      sign_in(user)
    end

    def expect_failure(message)
      expect(flash[:alert]).to eq(message)
      expect(response).to have_gitlab_http_status(:see_other)
      expect(response).to redirect_to profile_account_path
    end

    def expect_password_failure
      expect_failure(s_('Profiles|Invalid password'))
    end

    def expect_username_failure
      expect_failure(s_('Profiles|Invalid username'))
    end

    def expect_success
      expect(flash[:notice]).to eq s_('Profiles|Account scheduled for removal.')
      expect(response).to have_gitlab_http_status(:see_other)
      expect(response).to redirect_to new_user_session_path
    end

    context 'when user requires password confirmation' do
      it 'fails if password confirmation is not provided' do
        post :destroy

        expect_password_failure
      end

      it 'fails if password confirmation is wrong' do
        post :destroy, params: { password: 'wrong password' }

        expect_password_failure
      end

      it 'succeeds if password is confirmed' do
        post :destroy, params: { password: user.password }

        expect_success
      end
    end

    context 'when user does not require password confirmation' do
      before do
        stub_application_setting(password_authentication_enabled_for_web: false)
        stub_application_setting(password_authentication_enabled_for_git: false)
      end

      it 'fails if username confirmation is not provided' do
        post :destroy

        expect_username_failure
      end

      it 'fails if username confirmation is wrong' do
        post :destroy, params: { username: 'wrong username' }

        expect_username_failure
      end

      it 'succeeds if username is confirmed' do
        post :destroy, params: { username: user.username }

        expect_success
      end
    end

    context 'for prerequisites for account deletion' do
      context 'with solo-owned groups' do
        let(:group) { create(:group) }

        context 'if the user is the sole owner of at least one group' do
          before do
            create(:group_member, :owner, group: group, user: user)
          end

          it 'fails' do
            delete :destroy, params: { password: user.password }

            expect_failure(s_('Profiles|You must transfer ownership or delete groups you are an owner of before you can delete your account'))
          end
        end
      end
    end

    context 'when user did not accept app terms' do
      let(:user) { create(:user, accepted_term: nil) }

      before do
        stub_application_setting(password_authentication_enabled_for_web: false)
        stub_application_setting(password_authentication_enabled_for_git: false)
        stub_application_setting(enforce_terms: true)
      end

      it 'fails with message' do
        post :destroy, params: { username: user.username }

        expect_failure(s_('Profiles|You must accept the Terms of Service in order to perform this action.'))
      end
    end
  end
end
