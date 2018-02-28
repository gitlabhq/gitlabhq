require 'spec_helper'

describe PasswordsController do
  describe '#check_password_authentication_available' do
    before do
      @request.env["devise.mapping"] = Devise.mappings[:user]
    end

    context 'when password authentication is disabled' do
      it 'prevents a password reset' do
        stub_application_setting(password_authentication_enabled: false)

        post :create

        expect(flash[:alert]).to eq 'Password authentication is unavailable.'
      end
    end

    context 'when reset email belongs to an ldap user' do
      let(:user) { create(:omniauth_user, provider: 'ldapmain', email: 'ldapuser@gitlab.com') }

      it 'prevents a password reset' do
        post :create, user: { email: user.email }

        expect(flash[:alert]).to eq 'Password authentication is unavailable.'
      end
    end
  end
end
