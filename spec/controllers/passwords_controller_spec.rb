# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PasswordsController, feature_category: :system_access do
  include DeviseHelpers

  before do
    set_devise_mapping(context: @request)
  end

  describe '#check_password_authentication_available' do
    context 'when password authentication is disabled for the web interface and Git' do
      it 'prevents a password reset' do
        stub_application_setting(password_authentication_enabled_for_web: false)
        stub_application_setting(password_authentication_enabled_for_git: false)

        post :create

        expect(response).to have_gitlab_http_status(:found)
        expect(flash[:alert]).to eq _('Password authentication is unavailable.')
      end
    end
  end

  describe '#update' do
    render_views

    context 'updating the password' do
      subject do
        put :update, params: {
          user: {
            password: password,
            password_confirmation: password_confirmation,
            reset_password_token: reset_password_token
          }
        }
      end

      let(:password) { User.random_password }
      let(:password_confirmation) { password }
      let(:reset_password_token) { user.send_reset_password_instructions }
      let(:user) { create(:user, password_automatically_set: true, password_expires_at: 10.minutes.ago) }

      context 'password update is successful' do
        it 'updates the password-related flags' do
          subject
          user.reload

          expect(response).to redirect_to(new_user_session_path)
          expect(flash[:notice]).to include('password has been changed successfully')
          expect(user.password_automatically_set).to eq(false)
          expect(user.password_expires_at).to be_nil
        end
      end

      context 'password update is unsuccessful' do
        let(:password_confirmation) { 'not_the_same_as_password' }

        it 'does not update the password-related flags' do
          subject
          user.reload

          expect(response).to render_template(:edit)
          expect(response.body).to have_content("Password confirmation doesn't match Password")
          expect(user.password_automatically_set).to eq(true)
          expect(user.password_expires_at).not_to be_nil
        end
      end

      context 'password is weak' do
        let(:password) { "password" }

        it 'tracks the event' do
          subject

          expect(response.body).to have_content("must not contain commonly used combinations of words and letters")
          expect_snowplow_event(
            category: 'Gitlab::Tracking::Helpers::WeakPasswordErrorEvent',
            action: 'track_weak_password_error',
            controller: 'PasswordsController',
            method: 'create'
          )
        end
      end
    end
  end

  describe '#create' do
    let(:user) { create(:user) }
    let(:email) { user.email }

    subject(:perform_request) { post(:create, params: { user: { email: email } }) }

    context 'when parameter sanitization is applied' do
      let(:password) { User.random_password }
      let(:password_confirmation) { password }
      let(:reset_password_token) { user.send_reset_password_instructions }

      let(:user_hash) do
        {
          user: {
            email: email,
            password: password,
            password_confirmation: password_confirmation,
            reset_password_token: reset_password_token,
            admin: true
          }
        }
      end

      let(:malicious_user_hash) do
        {
          user: {
            email: [email, 'malicious_user@example.com'],
            password: password,
            password_confirmation: password_confirmation,
            reset_password_token: reset_password_token,
            admin: true,
            require_two_factor_authentication: false
          }
        }
      end

      let(:sanitized_params) { controller.send(:resource_params) }

      it 'returns a hash with permitted keys', :aggregate_failures do
        put :create, params: user_hash

        expect(sanitized_params.to_h).to include({
          email: email,
          password: password,
          password_confirmation: password_confirmation,
          reset_password_token: reset_password_token
        })

        expect(sanitized_params.to_h).not_to include({
          admin: true
        })
      end

      it 'returns a hash of only permitted scalars', :aggregate_failures do
        # PERMITTED_SCALAR_TYPES = [ String, Symbol, NilClass, Numeric, TrueClass, FalseClass, Date, Time]

        put :create, params: malicious_user_hash

        expect(sanitized_params.to_h).to include({
          password: password,
          password_confirmation: password_confirmation,
          reset_password_token: reset_password_token
        })

        expect(sanitized_params.to_h).not_to include({
          email: [email, 'malicious_user@example.com'],
          admin: true,
          require_two_factor_authentication: false
        })
      end
    end

    context 'when reCAPTCHA is disabled' do
      before do
        stub_application_setting(recaptcha_enabled: false)
      end

      it 'successfully sends password reset when reCAPTCHA is not solved' do
        perform_request

        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:notice]).to include 'If your email address exists in our database, you will receive a password recovery link at your email address in a few minutes.'
      end
    end

    context 'when reCAPTCHA is enabled' do
      before do
        stub_application_setting(recaptcha_enabled: true)
      end

      context 'when the reCAPTCHA is not solved' do
        before do
          Recaptcha.configuration.skip_verify_env.delete('test')
        end

        it 'displays an error' do
          perform_request

          expect(response).to render_template(:new)
          expect(flash[:alert]).to include _('There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.')
        end

        it 'sets gon variables' do
          Gon.clear

          perform_request

          expect(response).to render_template(:new)
          expect(Gon.all_variables).not_to be_empty
        end
      end

      it 'successfully sends password reset when reCAPTCHA is solved' do
        Recaptcha.configuration.skip_verify_env << 'test'

        perform_request

        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:notice]).to include 'If your email address exists in our database, you will receive a password recovery link at your email address in a few minutes.'
      end
    end

    context "sending 'Reset password instructions' email" do
      include EmailHelpers

      let_it_be(:user) { create(:user) }
      let_it_be(:user_confirmed_primary_email) { user.email }
      let_it_be(:user_confirmed_secondary_email) { create(:email, :confirmed, user: user, email: 'confirmed-secondary-email@example.com').email }
      let_it_be(:user_unconfirmed_secondary_email) { create(:email, user: user, email: 'unconfirmed-secondary-email@example.com').email }
      let_it_be(:unknown_email) { 'attacker@example.com' }
      let_it_be(:invalid_email) { 'invalid_email' }
      let_it_be(:sql_injection_email) { 'sql-injection-email@example.com OR 1=1' }
      let_it_be(:another_user_confirmed_primary_email) { create(:user).email }
      let_it_be(:another_user_unconfirmed_primary_email) { create(:user, :unconfirmed).email }

      before do
        reset_delivered_emails!

        perform_request

        perform_enqueued_jobs
      end

      context "when email param matches user's confirmed primary email" do
        let(:email) { user_confirmed_primary_email }

        it 'sends email to the primary email only' do
          expect_only_one_email_to_be_sent(subject: 'Reset password instructions', to: [user_confirmed_primary_email])
        end
      end

      context "when email param matches user's unconfirmed primary email" do
        let(:email) { another_user_unconfirmed_primary_email }

        # By default 'devise' gem allows password reset by unconfirmed primary email.
        # When user account with unconfirmed primary email that means it is unconfirmed.
        #
        # Password reset by unconfirmed primary email is very helpful from
        # security perspective. Example:
        # Malicious person creates user account on GitLab with someone's email.
        # If the email owner confirms the email for newly created account, the malicious person will be able
        # to sign in into the account by password they provided during account signup.
        # The malicious person could set up 2FA to the user account, after that
        # te email owner would not able to get access to that user account even
        # after performing password reset.
        # To deal with that case safely the email owner should reset password
        # for the user account first. That will make sure that after the user account
        # is confirmed the malicious person is not be able to sign in with
        # the password they provided during the account signup. Then email owner
        # could sign into the account, they will see a prompt to confirm the account email
        # to proceed. They can safely confirm the email and take over the account.
        # That is one of the reasons why password reset by unconfirmed primary email should be allowed.
        it 'sends email to the primary email only' do
          expect_only_one_email_to_be_sent(subject: 'Reset password instructions', to: [another_user_unconfirmed_primary_email])
        end
      end

      context "when email param matches user's confirmed secondary email" do
        let(:email) { user_confirmed_secondary_email }

        it 'sends email to the confirmed secondary email only' do
          expect_only_one_email_to_be_sent(subject: 'Reset password instructions', to: [user_confirmed_secondary_email])
        end
      end

      # While unconfirmed primary emails are linked with users accounts,
      # unconfirmed secondary emails should not be linked with any users till they are confirmed
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/356665
      #
      # In https://gitlab.com/gitlab-org/gitlab/-/issues/367823, it is considerd
      # to prevent reserving emails on Gitlab by unconfirmed secondary emails.
      # As per this issue, there might be cases that there are multiple users
      # with the same unconfirmed secondary emails. It would be impossible to identify for
      # what user account password reset is requested if password reset were allowed
      # by unconfirmed secondary emails.
      # Also note that it is not possible to request email confirmation for
      # unconfirmed secondary emails without having access to the user account.
      context "when email param matches user's unconfirmed secondary email" do
        let(:email) { user_unconfirmed_secondary_email }

        it 'does not send email to anyone' do
          should_not_email_anyone
        end
      end

      context 'when email param is unknown email' do
        let(:email) { unknown_email }

        it 'does not send email to anyone' do
          should_not_email_anyone
        end
      end

      context 'when email param is invalid email' do
        let(:email) { invalid_email }

        it 'does not send email to anyone' do
          should_not_email_anyone
        end
      end

      context 'when email param with attempt to cause SQL injection' do
        let(:email) { sql_injection_email }

        it 'does not send email to anyone' do
          should_not_email_anyone
        end
      end

      # See https://gitlab.com/gitlab-org/gitlab/-/issues/436084
      context 'when email param with multiple emails' do
        let(:email) do
          [
            user_confirmed_primary_email,
            user_confirmed_secondary_email,
            user_unconfirmed_secondary_email,
            unknown_email,
            another_user_confirmed_primary_email,
            another_user_unconfirmed_primary_email
          ]
        end

        it 'does not send email to anyone' do
          should_not_email_anyone
        end
      end
    end
  end
end
