require 'spec_helper'

describe RegistrationsController do
  describe '#create' do
    let(:user_params) { { user: { name: 'new_user', username: 'new_username', email: 'new@user.com', password: 'Any_password' } } }

    context 'email confirmation' do
      around do |example|
        perform_enqueued_jobs do
          example.run
        end
      end

      context 'when send_user_confirmation_email is false' do
        it 'signs the user in' do
          allow_any_instance_of(ApplicationSetting).to receive(:send_user_confirmation_email).and_return(false)

          expect { post(:create, user_params) }.not_to change { ActionMailer::Base.deliveries.size }
          expect(subject.current_user).not_to be_nil
        end
      end

      context 'when send_user_confirmation_email is true' do
        it 'does not authenticate user and sends confirmation email' do
          allow_any_instance_of(ApplicationSetting).to receive(:send_user_confirmation_email).and_return(true)

          post(:create, user_params)

          expect(ActionMailer::Base.deliveries.last.to.first).to eq(user_params[:user][:email])
          expect(subject.current_user).to be_nil
        end
      end

      context 'when signup_enabled? is false' do
        it 'redirects to sign_in' do
          allow_any_instance_of(ApplicationSetting).to receive(:signup_enabled?).and_return(false)

          expect { post(:create, user_params) }.not_to change(User, :count)
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context 'when reCAPTCHA is enabled' do
      before do
        stub_application_setting(recaptcha_enabled: true)
      end

      it 'displays an error when the reCAPTCHA is not solved' do
        # Without this, `verify_recaptcha` arbitraily returns true in test env
        Recaptcha.configuration.skip_verify_env.delete('test')

        post(:create, user_params)

        expect(response).to render_template(:new)
        expect(flash[:alert]).to include 'There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.'
      end

      it 'redirects to the dashboard when the recaptcha is solved' do
        # Avoid test ordering issue and ensure `verify_recaptcha` returns true
        unless Recaptcha.configuration.skip_verify_env.include?('test')
          Recaptcha.configuration.skip_verify_env << 'test'
        end

        post(:create, user_params)

        expect(flash[:notice]).to include 'Welcome! You have signed up successfully.'
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
      expect(response.status).to eq(303)
      expect(response).to redirect_to profile_account_path
    end

    def expect_password_failure
      expect_failure('Invalid password')
    end

    def expect_username_failure
      expect_failure('Invalid username')
    end

    def expect_success
      expect(flash[:notice]).to eq 'Account scheduled for removal.'
      expect(response.status).to eq(303)
      expect(response).to redirect_to new_user_session_path
    end

    context 'user requires password confirmation' do
      it 'fails if password confirmation is not provided' do
        post :destroy

        expect_password_failure
      end

      it 'fails if password confirmation is wrong' do
        post :destroy, password: 'wrong password'

        expect_password_failure
      end

      it 'succeeds if password is confirmed' do
        post :destroy, password: '12345678'

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
        post :destroy, username: 'wrong username'

        expect_username_failure
      end

      it 'succeeds if username is confirmed' do
        post :destroy, username: user.username

        expect_success
      end
    end
  end
end
