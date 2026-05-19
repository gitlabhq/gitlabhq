# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Step-up authentication', :with_current_organization, :js, feature_category: :shared do
  let_it_be(:extern_uid) { 'my-uid' }
  let_it_be(:provider_oidc) { 'openid_connect' }

  let(:provider_oidc_config_with_step_up_auth) do
    GitlabSettings::Options.new(
      name: provider_oidc,
      step_up_auth: {
        admin_mode: {
          id_token: {
            required: { acr: 'gold' }
          }
        }
      }
    )
  end

  let(:additional_info_rejected_step_up_auth) { { extra: { raw_info: { acr: 'bronze' } } } }
  let(:additional_info_success_step_up_auth) { { extra: { raw_info: { acr: 'gold' } } } }

  around do |example|
    with_omniauth_full_host { example.run }
  end

  def expect_admin_sign_in_success
    expect(page).to have_content(_('Admin mode is active.'))
    expect(page).to have_current_path admin_root_path, ignore_query: true
  end

  def expect_admin_sign_in_fail
    expect(page).to have_content(s_('AdminMode|Step-up authentication failed.'))
  end

  context 'for admin mode' do
    let_it_be(:admin) do
      create(:omniauth_user, :admin, password_automatically_set: false, extern_uid: extern_uid, provider: provider_oidc)
    end

    before do
      stub_omniauth_setting(enabled: true, auto_link_user: true, providers: [provider_oidc_config_with_step_up_auth])
    end

    context 'when step-up auth conditions fulfilled' do
      before do
        sign_in(admin)
      end

      it 'user enters admin mode successfully' do
        gitlab_enable_admin_mode_sign_in_via(provider_oidc, admin, extern_uid,
          additional_info: additional_info_success_step_up_auth)

        expect_admin_sign_in_success
      end

      it 'user enters admin mode, leaves admin mode and cannot re-enter admin mode without re-authentication' do
        gitlab_enable_admin_mode_sign_in_via(provider_oidc, admin, extern_uid,
          additional_info: additional_info_success_step_up_auth)

        expect_admin_sign_in_success

        # Leave admin mode
        leave_admin_mode

        # Attempt to access the admin area again
        visit admin_root_path

        # Ensure re-authentication is required
        expect(page).to have_current_path new_admin_session_path
        expect(page).to have_content('Re-authentication required')
      end

      it 'user enters admin mode and navigates successfully between non-admin and admin areas' do
        gitlab_enable_admin_mode_sign_in_via(provider_oidc, admin, extern_uid,
          additional_info: additional_info_success_step_up_auth)

        expect_admin_sign_in_success

        # Go to non-admin page
        visit root_path
        expect(page).to have_current_path root_path, ignore_query: true

        # Return to admin area
        visit admin_root_path
        expect(page).to have_current_path admin_root_path, ignore_query: true
        expect(page).not_to have_content(_('Admin mode is active.'))
      end

      context 'when feature flag :omniauth_step_up_auth_for_admin_mode is disabled' do
        before do
          stub_feature_flags(omniauth_step_up_auth_for_admin_mode: false)
        end

        it 'user enters admin mode' do
          gitlab_enable_admin_mode_sign_in_via(provider_oidc, admin, extern_uid,
            additional_info: additional_info_success_step_up_auth)

          expect_admin_sign_in_success
        end
      end
    end

    context 'when step-up auth conditions not fulfilled' do
      before do
        sign_in(admin)
      end

      it 'user cannot enter admin mode and shows correct info message' do
        gitlab_enable_admin_mode_sign_in_via(provider_oidc, admin, extern_uid,
          additional_info: additional_info_rejected_step_up_auth, expect_fail: true)

        expect_admin_sign_in_fail
      end

      context 'when feature flag :omniauth_step_up_auth_for_admin_mode is disabled' do
        before do
          stub_feature_flags(omniauth_step_up_auth_for_admin_mode: false)
        end

        it 'user enters admin mode successfully' do
          gitlab_enable_admin_mode_sign_in_via(provider_oidc, admin, extern_uid,
            additional_info: additional_info_rejected_step_up_auth)

          expect_admin_sign_in_success
        end
      end
    end

    context 'for different initial sign-in methods' do
      shared_examples 'successful step-up auth process' do
        it 'user enters admin mode with successful step-up auth process' do
          expect(page).to have_current_path root_path, ignore_query: true

          gitlab_enable_admin_mode_sign_in_via(provider_oidc, admin, extern_uid,
            additional_info: additional_info_rejected_step_up_auth, expect_fail: true)

          expect_admin_sign_in_fail

          gitlab_enable_admin_mode_sign_in_via(provider_oidc, admin, extern_uid,
            additional_info: additional_info_success_step_up_auth)

          expect_admin_sign_in_success
        end
      end

      context 'when user signed in initially with username and password' do
        before do
          gitlab_sign_in(admin)
        end

        it_behaves_like 'successful step-up auth process'
      end

      context 'when user signed in initially with same omniauth provider (openid_connect)' do
        before do
          gitlab_sign_in_via(provider_oidc, admin, extern_uid)
        end

        it_behaves_like 'successful step-up auth process'
      end

      context 'when user signed in initially with another omniauth provider (github)' do
        let(:provider_github) { 'github' }
        let(:provider_github_config) { GitlabSettings::Options.new(name: provider_github) }
        let(:provider_github_extern_uid) { 'github_user_uid' }

        before do
          # Add github identity to admin user
          admin.identities << create(:identity, provider: provider_github, extern_uid: provider_github_extern_uid)

          # Enable github provider
          stub_omniauth_setting(enabled: true, auto_link_user: true,
            providers: [provider_oidc_config_with_step_up_auth, provider_github_config])

          gitlab_sign_in_via(provider_github, admin, provider_github_extern_uid)
        end

        it_behaves_like 'successful step-up auth process'
      end
    end
  end
end
