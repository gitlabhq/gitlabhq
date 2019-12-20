# frozen_string_literal: true

require 'spec_helper'

describe PasswordsController do
  describe '#check_password_authentication_available' do
    before do
      @request.env["devise.mapping"] = Devise.mappings[:user]
    end

    context 'when password authentication is disabled for the web interface and Git' do
      it 'prevents a password reset' do
        stub_application_setting(password_authentication_enabled_for_web: false)
        stub_application_setting(password_authentication_enabled_for_git: false)

        post :create

        expect(response).to have_gitlab_http_status(302)
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
end
