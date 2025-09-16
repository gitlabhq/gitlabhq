# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group Step-up Authentication Settings', :js, feature_category: :groups_and_projects do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user, owner_of: group) }

  let(:ommiauth_provider_config_oidc) do
    GitlabSettings::Options.new(
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
    click_button 'Save changes'

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
end
