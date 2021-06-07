# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PasswordsController do
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

    context 'when reset email belongs to an ldap user' do
      let(:user) { create(:omniauth_user, provider: 'ldapmain', email: 'ldapuser@gitlab.com') }

      it 'prevents a password reset' do
        post :create, params: { user: { email: user.email } }

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

      it 'sets the username and caller_id in the context' do
        expect(controller).to receive(:update).and_wrap_original do |m, *args|
          m.call(*args)

          expect(Gitlab::ApplicationContext.current)
            .to include('meta.user' => user.username,
                        'meta.caller_id' => 'PasswordsController#update')
        end

        subject
      end
    end
  end
end
