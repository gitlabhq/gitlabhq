# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group step-up authentication', :with_current_organization, :js, feature_category: :system_access do
  let_it_be(:provider_oidc_extern_uid) { 'oidc_user_uid' }
  let_it_be(:provider_oidc) { 'openid_connect' }
  let_it_be_with_reload(:group) { create(:group) }

  let_it_be(:user) do
    create(:omniauth_user,
      password_automatically_set: false,
      extern_uid: provider_oidc_extern_uid,
      provider: provider_oidc,
      developer_of: group
    )
  end

  let(:provider_oidc_config_with_step_up_auth) do
    GitlabSettings::Options.new(
      name: provider_oidc,
      step_up_auth: {
        namespace: {
          id_token: {
            required: { acr: 'gold' }
          }
        }
      }
    )
  end

  let(:provider_oidc_config_without_step_up_auth) do
    GitlabSettings::Options.new(name: provider_oidc)
  end

  let(:additional_info_rejected_step_up_auth) { { extra: { raw_info: { acr: 'bronze' } } } }
  let(:additional_info_success_step_up_auth) { { extra: { raw_info: { acr: 'gold' } } } }

  around do |example|
    with_omniauth_full_host { example.run }
  end

  shared_examples 'user can access group page successfully' do
    it 'grants access to the group page' do
      # First visit should redirect to step-up auth
      visit group_path(group)

      expect(page).to have_current_path(group_path(group))
      expect(page).to have_content(group.name)
    end
  end

  context 'when step-up auth provider exists' do
    before do
      stub_omniauth_setting(enabled: true, auto_link_user: true, providers: [provider_oidc_config_with_step_up_auth])
    end

    context 'when group requires step-up authentication' do
      before do
        group.namespace_settings.update!(step_up_auth_required_oauth_provider: provider_oidc)
      end

      context 'when step-up auth conditions are fulfilled' do
        before do
          sign_in(user)
        end

        it 'completes full step-up auth flow with comprehensive navigation' do
          # Test Case 1: Initial redirect and successful step-up authentication
          # First visit should redirect to step-up auth page
          visit group_path(group)
          expect(page).to have_current_path(new_group_step_up_auth_path(group))

          # Perform successful step-up auth
          gitlab_group_step_up_auth_sign_in_via(provider_oidc, user, provider_oidc_extern_uid,
            additional_info: additional_info_success_step_up_auth)

          # Should now be able to access the group page
          visit group_path(group)
          expect(page).to have_current_path(group_path(group))
          expect(page).to have_content(group.name)

          # Test Case 2: Navigation to different group pages
          # Verify step-up auth session persists across different group routes
          visit edit_group_path(group)
          expect(page).to have_current_path(edit_group_path(group))

          visit issues_group_path(group)
          expect(page).to have_current_path(group_work_items_path(group, type: ['issue']))

          # Test Case 3: Navigation in and out of group scope
          # Verify step-up auth session persists when navigating away and returning
          visit root_path
          expect(page).to have_current_path(root_path)

          visit group_path(group)
          expect(page).to have_current_path(group_path(group))
          expect(page).not_to have_current_path(new_group_step_up_auth_path(group))
        end

        context 'when feature flag :omniauth_step_up_auth_for_namespace is disabled' do
          before do
            stub_feature_flags(omniauth_step_up_auth_for_namespace: false)
          end

          it_behaves_like 'user can access group page successfully'
        end
      end

      context 'for different initial sign-in methods' do
        shared_examples 'successful group step-up auth process' do
          before do
            wait_for_requests
            expect(page).to have_current_path(root_path, ignore_query: true) # rubocop:disable RSpec/ExpectInHook -- Just to ensure our setup is correct

            # Try to access group - should redirect to step-up auth
            visit group_path(group)
            expect(page).to have_current_path(new_group_step_up_auth_path(group)) # rubocop:disable RSpec/ExpectInHook -- Just to ensure our setup is correct

            # Then succeed with step-up auth
            gitlab_group_step_up_auth_sign_in_via(
              provider_oidc, user,
              provider_oidc_extern_uid,
              additional_info: additional_info_success_step_up_auth
            )
          end

          it_behaves_like 'user can access group page successfully'
        end

        context 'when user signed in initially with username and password' do
          before do
            gitlab_sign_in(user)
          end

          it_behaves_like 'successful group step-up auth process'
        end

        context 'when user signed in initially with same omniauth provider (openid_connect)' do
          before do
            gitlab_sign_in_via(provider_oidc, user, provider_oidc_extern_uid)
          end

          it_behaves_like 'successful group step-up auth process'
        end

        context 'when user signed in initially with another omniauth provider (github)' do
          let(:provider_github) { 'github' }
          let(:provider_github_config) { GitlabSettings::Options.new(name: provider_github) }
          let(:provider_github_extern_uid) { "github_user_uid" }

          before do
            # Add both github and openid_connect identities to user
            user.identities << create(:identity, provider: provider_github, extern_uid: provider_github_extern_uid)

            # Enable both providers
            stub_omniauth_setting(enabled: true, auto_link_user: true, providers: [
              provider_oidc_config_with_step_up_auth,
              provider_github_config
            ])

            gitlab_sign_in_via(provider_github, user, provider_github_extern_uid)
          end

          it_behaves_like 'successful group step-up auth process'
        end
      end

      context 'when step-up auth conditions are not fulfilled' do
        before do
          sign_in(user)
        end

        it 'redirects to step-up auth page when authentication fails' do
          # Initial redirect when step-up auth is required
          visit group_path(group)
          expect(page).to have_current_path(new_group_step_up_auth_path(group))

          # Failed step-up auth redirects back to step-up auth page
          # Authentication fails due to insufficient acr level
          gitlab_group_step_up_auth_sign_in_via(provider_oidc, user, provider_oidc_extern_uid,
            additional_info: additional_info_rejected_step_up_auth)
          expect(page).to have_current_path(new_group_step_up_auth_path(group))
          expect(page).to have_content('Step-up authentication required This group requires additional authentication.')
        end

        it 'allows user to retry step-up auth after initial failure' do
          visit group_path(group)

          # First attempt - authentication fails
          gitlab_group_step_up_auth_sign_in_via(provider_oidc, user, provider_oidc_extern_uid,
            additional_info: additional_info_rejected_step_up_auth)
          expect(page).to have_current_path(new_group_step_up_auth_path(group))

          # Second attempt - authentication succeeds with correct acr level
          gitlab_group_step_up_auth_sign_in_via(provider_oidc, user, provider_oidc_extern_uid,
            additional_info: additional_info_success_step_up_auth)

          # Verify successful access to group and navigation to different pages
          expect(page).to have_current_path(group_path(group))
          expect(page).to have_content(group.name)

          visit issues_group_path(group)
          expect(page).to have_current_path(group_work_items_path(group, type: ['issue']))
        end
      end
    end

    context 'when group does not require step-up authentication' do
      before do
        group.namespace_settings.update!(step_up_auth_required_oauth_provider: nil)

        sign_in(user)
      end

      it_behaves_like 'user can access group page successfully'
    end
  end

  context 'when step-up auth provider does not exists' do
    before do
      stub_omniauth_setting(enabled: true, auto_link_user: true, providers: [provider_oidc_config_without_step_up_auth])

      sign_in(user)
    end

    it_behaves_like 'user can access group page successfully'
  end

  private

  # Helper method for group step-up authentication
  # This simulates the step-up auth flow for groups
  def gitlab_group_step_up_auth_sign_in_via(provider, user, uid, additional_info: {})
    mock_auth_hash(provider, uid, user.email, additional_info: additional_info)
    click_button Gitlab::Auth::OAuth::Provider.label_for(provider)
  end
end
