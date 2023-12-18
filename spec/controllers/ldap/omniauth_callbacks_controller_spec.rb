# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ldap::OmniauthCallbacksController, type: :controller, feature_category: :system_access do
  include_context 'Ldap::OmniauthCallbacksController'

  it 'allows sign in' do
    post provider

    expect(request.env['warden']).to be_authenticated
  end

  it 'creates an authentication event record' do
    expect { post provider }.to change { AuthenticationEvent.count }.by(1)
    expect(AuthenticationEvent.last.provider).to eq(provider.to_s)
  end

  context 'with sign in prevented' do
    let(:ldap_settings) { ldap_setting_defaults.merge(prevent_ldap_sign_in: true) }

    it 'does not allow sign in' do
      expect { post provider }.to raise_error(ActionController::UrlGenerationError)
    end
  end

  it 'respects remember me checkbox' do
    expect do
      post provider, params: { remember_me: '1' }
    end.to change { user.reload.remember_created_at }.from(nil)
  end

  context 'with 2FA' do
    let(:user) { create(:omniauth_user, :two_factor_via_otp, extern_uid: uid, provider: provider) }

    it 'passes remember_me to the Devise view' do
      post provider, params: { remember_me: '1' }

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
    let(:user) { create(:user) }

    before do
      stub_omniauth_setting(block_auto_created_users: false)
    end

    it 'is allowed' do
      post provider

      expect(request.env['warden']).to be_authenticated
    end
  end

  describe 'enable admin mode' do
    include_context 'custom session'

    before do
      sign_in user
    end

    context 'with a regular user' do
      it 'cannot be enabled' do
        reauthenticate_and_check_admin_mode(expected_admin_mode: false)

        expect(response).to redirect_to(root_path)
      end
    end

    context 'with an admin user' do
      let(:user) { create(:omniauth_user, :admin, extern_uid: uid, provider: provider) }

      context 'when requested first' do
        before do
          subject.current_user_mode.request_admin_mode!
        end

        it 'can be enabled' do
          reauthenticate_and_check_admin_mode(expected_admin_mode: true)

          expect(response).to redirect_to(admin_root_path)
        end
      end

      context 'when not requested first' do
        it 'cannot be enabled' do
          reauthenticate_and_check_admin_mode(expected_admin_mode: false)

          expect(response).to redirect_to(root_path)
        end
      end
    end
  end

  def reauthenticate_and_check_admin_mode(expected_admin_mode:)
    # Initially admin mode disabled
    expect(subject.current_user_mode.admin_mode?).to be(false)

    # Trigger OmniAuth admin mode flow and expect admin mode status
    post provider

    expect(request.env['warden']).to be_authenticated
    expect(subject.current_user_mode.admin_mode?).to be(expected_admin_mode)
  end
end
