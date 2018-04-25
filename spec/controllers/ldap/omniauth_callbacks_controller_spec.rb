require 'spec_helper'

describe Ldap::OmniauthCallbacksController do
  include_context 'Ldap::OmniauthCallbacksController'

  it 'allows sign in' do
    post provider

    expect(request.env['warden']).to be_authenticated
  end

  it 'respects remember me checkbox' do
    expect do
      post provider, remember_me: '1'
    end.to change { user.reload.remember_created_at }.from(nil)
  end

  context 'with 2FA' do
    let(:user) { create(:omniauth_user, :two_factor_via_otp, extern_uid: uid, provider: provider) }

    it 'passes remember_me to the Devise view' do
      post provider, remember_me: '1'

      expect(assigns[:user].remember_me).to eq '1'
    end
  end

  context 'access denied' do
    let(:valid_login?) { false }

    it 'warns the user' do
      post provider

      expect(flash[:alert]).to match(/Access denied for your LDAP account*/)
    end

    it "doesn't authenticate user" do
      post provider

      expect(request.env['warden']).not_to be_authenticated
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context 'sign up' do
    let(:user) { double(email: 'new@example.com') }

    before do
      stub_omniauth_setting(block_auto_created_users: false)
    end

    it 'is allowed' do
      post provider

      expect(request.env['warden']).to be_authenticated
    end
  end
end
