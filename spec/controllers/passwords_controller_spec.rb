require 'spec_helper'

describe PasswordsController do
  describe '#prevent_ldap_reset' do
    before do
      @request.env["devise.mapping"] = Devise.mappings[:user]
    end

    context 'when password authentication is disabled' do
      it 'allows password reset' do
        stub_application_setting(password_authentication_enabled: false)

        post :create

        expect(response).to have_http_status(302)
      end
    end

    context 'when reset email belongs to an ldap user' do
      let(:user) { create(:omniauth_user, provider: 'ldapmain', email: 'ldapuser@gitlab.com') }

      it 'prevents a password reset' do
        post :create, user: { email: user.email }

        expect(flash[:alert]).to eq('Cannot reset password for LDAP user.')
      end
    end
  end
end
