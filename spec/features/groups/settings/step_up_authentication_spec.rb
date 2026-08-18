# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group Step-up Authentication Settings', :js, feature_category: :groups_and_projects do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user, owner_of: group) }

  let(:ommiauth_provider_config_oidc) do
    Gitlab::Configs.build_options(
      name: 'openid_connect',
      label: 'OpenID Connect',
      step_up_auth: {
        namespace: {
          id_token: {
            required: {
              acr: 'gold'
            }
          }
        }
      }
    )
  end

  before do
    sign_in(user)

    stub_omniauth_setting(enabled: true, providers: [ommiauth_provider_config_oidc])
  end

  it 'displays step-up authentication settings in group permissions and allows enabling step-up authentication' do
    visit edit_group_path(group, anchor: 'js-permissions-settings')

    expect(page).to have_content('Step-up authentication')
    expect(page).to have_select('group_step_up_auth_required_oauth_provider')

    select 'OpenID Connect', from: 'group_step_up_auth_required_oauth_provider'

    within_testid("permissions-settings") do
      click_button 'Save changes'
    end

    expect(page).to have_content("Group '#{group.name}' was successfully updated.")

    expect(group.reload.namespace_settings.step_up_auth_required_oauth_provider).to eq('openid_connect')
  end

  context 'when feature flag is disabled' do
    before do
      stub_feature_flags(omniauth_step_up_auth_for_namespace: false)
    end

    it 'does not display step-up authentication settings' do
      visit edit_group_path(group, anchor: 'js-permissions-settings')

      expect(page).not_to have_content('Step-up authentication')
      expect(page).not_to have_select('group_step_up_auth_required_oauth_provider')
    end
  end

  describe 'provider configuration' do
    context 'with configured step-up omniauth providers' do
      let_it_be(:omniauth_provider_config_oidc) do
        Gitlab::Configs.build_options(
          name: 'openid_connect',
          label: 'OpenID Connect',
          step_up_auth: {
            namespace: {
              id_token: {
                required: { acr: 'gold' }
              }
            }
          }
        )
      end

      before do
        stub_omniauth_setting(enabled: true, providers: [omniauth_provider_config_oidc])
        allow(Devise).to receive(:omniauth_providers).and_return([omniauth_provider_config_oidc.name])
      end

      context 'when group has no parent' do
        it 'allows configuring step-up authentication' do
          visit edit_group_path(group)

          within_testid('permissions-settings') do
            expect(page).to have_content('Step-up authentication')
            expect(page).to have_select('Step-up authentication', disabled: false, with_options: ['OpenID Connect'])
          end
        end

        it 'can select and save step-up authentication provider' do
          visit edit_group_path(group)

          within_testid('permissions-settings') do
            select 'OpenID Connect', from: 'group_step_up_auth_required_oauth_provider'
            click_button 'Save changes'
          end

          expect(page).to have_text("Group '#{group.name}' was successfully updated")
          expect(group.reload.namespace_settings.step_up_auth_required_oauth_provider).to eq('openid_connect')
        end

        it 'can disable step-up authentication' do
          group.namespace_settings.update!(step_up_auth_required_oauth_provider: 'openid_connect')

          visit edit_group_path(group)

          within_testid('permissions-settings') do
            select 'Disabled', from: 'group_step_up_auth_required_oauth_provider'
            click_button 'Save changes'
          end

          expect(page).to have_text("Group '#{group.name}' was successfully updated")
          expect(group.reload.namespace_settings.step_up_auth_required_oauth_provider).to be_nil
        end
      end

      context 'when group inherits step-up authentication from parent' do
        let_it_be_with_reload(:grandparent_group) { create(:group, owners: [user]) }
        let_it_be_with_reload(:parent_group) { create(:group, parent: grandparent_group, owners: [user]) }
        let_it_be_with_reload(:child_group) { create(:group, parent: parent_group, owners: [user]) }

        before do
          parent_group.namespace_settings.update!(step_up_auth_required_oauth_provider: 'openid_connect')
        end

        it 'shows complete inheritance alert with parent group name and guidance', :aggregate_failures do
          visit edit_group_path(child_group)

          within_testid('permissions-settings') do
            expect(page).to have_content('Step-up authentication')

            # Check the alert exists and has correct properties
            alert = find_by_testid('step-up-auth-inheritance-alert')
            expect(alert).to be_present
            expect(alert[:class]).to include('gl-alert-info')
            expect(alert).to have_content(
              "Step-up authentication is inherited from parent group \"#{parent_group.name}\""
            )
          end
        end

        it 'disables form controls and shows inherited value with proper accessibility' do
          visit edit_group_path(child_group)

          within_testid('permissions-settings') do
            expect(page).to have_content('Step-up authentication')

            # Check inheritance alert with complete messaging
            expect(find_by_testid('step-up-auth-inheritance-alert'))
              .to have_content("Step-up authentication is inherited from parent group \"#{parent_group.name}\"")

            # Form controls should be disabled with correct inherited value
            expect(page).to have_select('Step-up authentication', disabled: true, selected: 'OpenID Connect')
          end
        end
      end
    end

    context 'without configured step-up omniauth providers' do
      before do
        stub_omniauth_setting(enabled: true, providers: [])
        allow(Devise).to receive(:omniauth_providers).and_return([])
      end

      it 'shows only disabled option' do
        visit edit_group_path(group)

        within_testid('permissions-settings') do
          expect(page).to have_content('Step-up authentication')
          expect(page).to have_select('Step-up authentication', disabled: false, selected: 'Disabled', with_options: [])
        end
      end
    end
  end
end
