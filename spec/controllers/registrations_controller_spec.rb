# frozen_string_literal: true

require 'spec_helper'

describe RegistrationsController do
  include TermsHelper

  before do
    stub_feature_flags(invisible_captcha: false)
  end

  describe '#new' do
    subject { get :new }

    context 'with the experimental signup flow enabled and the user is part of the experimental group' do
      before do
        stub_experiment(signup_flow: true)
        stub_experiment_for_user(signup_flow: true)
      end

      it 'tracks the event with the right parameters' do
        expect(Gitlab::Tracking).to receive(:event).with(
          'Growth::Acquisition::Experiment::SignUpFlow',
          'start',
          label: anything,
          property: 'experimental_group'
        )
        subject
      end

      it 'renders new template and sets the resource variable' do
        expect(subject).to render_template(:new)
        expect(response).to have_gitlab_http_status(200)
        expect(assigns(:resource)).to be_a(User)
      end
    end

    context 'with the experimental signup flow enabled and the user is part of the control group' do
      before do
        stub_experiment(signup_flow: true)
        stub_experiment_for_user(signup_flow: false)
      end

      it 'does not track the event' do
        expect(Gitlab::Tracking).not_to receive(:event)
        subject
      end

      it 'renders new template and sets the resource variable' do
        subject
        expect(response).to have_gitlab_http_status(302)
        expect(response).to redirect_to(new_user_session_path(anchor: 'register-pane'))
      end
    end
  end

  describe '#create' do
    let(:base_user_params) { { name: 'new_user', username: 'new_username', email: 'new@user.com', password: 'Any_password' } }
    let(:user_params) { { user: base_user_params } }

    context 'email confirmation' do
      around do |example|
        perform_enqueued_jobs do
          example.run
        end
      end

      context 'when send_user_confirmation_email is false' do
        it 'signs the user in' do
          stub_application_setting(send_user_confirmation_email: false)

          expect { post(:create, params: user_params) }.not_to change { ActionMailer::Base.deliveries.size }
          expect(subject.current_user).not_to be_nil
        end
      end

      context 'when send_user_confirmation_email is true' do
        before do
          stub_application_setting(send_user_confirmation_email: true)
        end

        context 'when soft email confirmation is not enabled' do
          before do
            stub_feature_flags(soft_email_confirmation: false)
            allow(User).to receive(:allow_unconfirmed_access_for).and_return 0
          end

          it 'does not authenticate the user and sends a confirmation email' do
            post(:create, params: user_params)

            expect(ActionMailer::Base.deliveries.last.to.first).to eq(user_params[:user][:email])
            expect(subject.current_user).to be_nil
          end
        end

        context 'when soft email confirmation is enabled' do
          before do
            stub_feature_flags(soft_email_confirmation: true)
            allow(User).to receive(:allow_unconfirmed_access_for).and_return 2.days
          end

          it 'authenticates the user and sends a confirmation email' do
            post(:create, params: user_params)

            expect(ActionMailer::Base.deliveries.last.to.first).to eq(user_params[:user][:email])
            expect(response).to redirect_to(dashboard_projects_path)
          end
        end
      end

      context 'when signup_enabled? is false' do
        it 'redirects to sign_in' do
          stub_application_setting(signup_enabled: false)

          expect { post(:create, params: user_params) }.not_to change(User, :count)
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

      it 'displays an error when the reCAPTCHA is not solved' do
        allow_any_instance_of(described_class).to receive(:verify_recaptcha).and_return(false)

        post(:create, params: user_params)

        expect(response).to render_template(:new)
        expect(flash[:alert]).to eq(_('There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.'))
      end

      it 'redirects to the dashboard when the recaptcha is solved' do
        post(:create, params: user_params)

        expect(flash[:notice]).to eq(I18n.t('devise.registrations.signed_up'))
      end

      it 'does not require reCAPTCHA if disabled by feature flag' do
        stub_feature_flags(registrations_recaptcha: false)

        post(:create, params: user_params)

        expect(controller).not_to receive(:verify_recaptcha)
        expect(flash[:alert]).to be_nil
        expect(flash[:notice]).to eq(I18n.t('devise.registrations.signed_up'))
      end
    end

    context 'when invisible captcha is enabled' do
      before do
        stub_feature_flags(invisible_captcha: true)
        InvisibleCaptcha.timestamp_enabled = true
        InvisibleCaptcha.timestamp_threshold = treshold
      end

      after do
        InvisibleCaptcha.timestamp_enabled = false
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
            expect(response).to have_gitlab_http_status(200)
            expect(response.body).to be_empty
          end
        end
      end

      describe 'timestamp spam detection' do
        let(:auth_log_message) { 'Invisible_Captcha_Timestamp_Request' }

        context 'the sign up form has been submitted without the invisible_captcha_timestamp parameter' do
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

        context 'the sign up form has been submitted too quickly' do
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

    context 'when terms are enforced' do
      before do
        enforce_terms
      end

      it 'redirects back with a notice when the checkbox was not checked' do
        post :create, params: user_params

        expect(flash[:alert]).to eq(_('You must accept our Terms of Service and privacy policy in order to register an account'))
      end

      it 'creates the user with agreement when terms are accepted' do
        post :create, params: user_params.merge(terms_opt_in: '1')

        expect(subject.current_user).to be_present
        expect(subject.current_user.terms_accepted?).to be(true)
      end
    end

    describe 'tracking data' do
      context 'with the experimental signup flow enabled and the user is part of the control group' do
        before do
          stub_experiment(signup_flow: true)
          stub_experiment_for_user(signup_flow: false)
        end

        it 'tracks the event with the right parameters' do
          expect(Gitlab::Tracking).to receive(:event).with(
            'Growth::Acquisition::Experiment::SignUpFlow',
            'end',
            label: anything,
            property: 'control_group'
          )
          post :create, params: user_params
        end
      end

      context 'with the experimental signup flow enabled and the user is part of the experimental group' do
        before do
          stub_experiment(signup_flow: true)
          stub_experiment_for_user(signup_flow: true)
        end

        it 'does not track the event' do
          expect(Gitlab::Tracking).not_to receive(:event)
          post :create, params: user_params
        end
      end
    end

    it "logs a 'User Created' message" do
      stub_feature_flags(registrations_recaptcha: false)

      expect(Gitlab::AppLogger).to receive(:info).with(/\AUser Created: username=new_username email=new@user.com.+\z/).and_call_original

      post(:create, params: user_params)
    end

    it 'handles when params are new_user' do
      post(:create, params: { new_user: base_user_params })

      expect(subject.current_user).not_to be_nil
    end
  end

  describe '#destroy' do
    let(:user) { create(:user) }

    before do
      sign_in(user)
    end

    def expect_failure(message)
      expect(flash[:alert]).to eq(message)
      expect(response.status).to eq(303)
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
      expect(response.status).to eq(303)
      expect(response).to redirect_to new_user_session_path
    end

    context 'user requires password confirmation' do
      it 'fails if password confirmation is not provided' do
        post :destroy

        expect_password_failure
      end

      it 'fails if password confirmation is wrong' do
        post :destroy, params: { password: 'wrong password' }

        expect_password_failure
      end

      it 'succeeds if password is confirmed' do
        post :destroy, params: { password: '12345678' }

        expect_success
      end
    end

    context 'user does not require password confirmation' do
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
  end

  describe '#update_registration' do
    before do
      stub_experiment(signup_flow: true)
      stub_experiment_for_user(signup_flow: true)
      sign_in(create(:user))
    end

    it 'tracks the event with the right parameters' do
      expect(Gitlab::Tracking).to receive(:event).with(
        'Growth::Acquisition::Experiment::SignUpFlow',
        'end',
        label: anything,
        property: 'experimental_group'
      )
      patch :update_registration, params: { user: { name: 'New name', role: 'software_developer', setup_for_company: 'false' } }
    end
  end
end
