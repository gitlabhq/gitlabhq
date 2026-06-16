# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User Settings > Granular personal access tokens > tokens drawer',
  :with_current_organization, :js, feature_category: :system_access do
  let_it_be(:user) { create(:user, :with_namespace) }
  let_it_be(:group) { create(:group) }

  let_it_be(:active_token) do
    create(:granular_pat,
      user: user,
      name: 'Active PAT',
      description: 'Active PAT description',
      expires_at: 1.month.from_now,
      last_used_at: 1.day.ago,
      boundary: ::Authz::Boundary.for(group),
      permissions: [:read_member_role, :create_member_role]
    )
  end

  let_it_be(:active_token_user_scope) do
    create(:granular_scope,
      organization: active_token.organization,
      boundary: ::Authz::Boundary.for(::Authz::GranularScope::Access::USER),
      permissions: [:read_user]
    )
  end

  let_it_be(:active_token_user_scope_join) do
    create(:personal_access_token_granular_scope,
      personal_access_token: active_token,
      granular_scope: active_token_user_scope,
      organization: active_token.organization
    )
  end

  let_it_be(:legacy_active_token) do
    create(:personal_access_token,
      user: user,
      name: 'Legacy active token',
      expires_at: 20.days.from_now
    )
  end

  before_all do
    group.add_owner(user)
  end

  before do
    stub_feature_flags(granular_personal_access_tokens: true)
    sign_in(user)
    visit user_settings_personal_access_tokens_path
  end

  context 'for legacy tokens' do
    it 'shows the token name, status and type' do
      open_drawer_for(legacy_active_token.name)

      within('#contextual-panel-portal') do
        expect(page).to have_text(legacy_active_token.name)
        expect(page).to have_text('Legacy token')
        expect(page).to have_text('Created on')
        expect(page).to have_text(legacy_active_token.description)
      end
    end

    it 'shows the expiry, last used and IP usage fields' do
      open_drawer_for(legacy_active_token.name)

      within('#contextual-panel-portal') do
        expect(page).to have_text('Expires')
        expect(page).to have_text('Last used')
        expect(page).to have_text('IP Usage')
        expect(page).to have_text('No IP activity recorded yet.')
      end
    end

    it 'shows the legacy scope list with a reduce-scope warning for legacy tokens' do
      open_drawer_for(legacy_active_token.name)

      within('#contextual-panel-portal') do
        expect(page).to have_text('Scopes')
        expect(page).to have_text('Consider reducing scope')
        expect(page).to have_text('API')
      end
    end

    it 'shows revoke and rotate actions' do
      open_drawer_for(active_token.name)

      within('#contextual-panel-portal') do
        expect(page).to have_selector('[data-testid="revoke-token"]')
        expect(page).to have_selector('[data-testid="rotate-token"]')
      end
    end

    it 'hides the duplicate action' do
      open_drawer_for(legacy_active_token.name)

      within('#contextual-panel-portal') do
        expect(page).not_to have_selector('[data-testid="duplicate-token"]')
      end
    end
  end

  context 'for granular tokens' do
    it 'shows the token name, status, and type' do
      open_drawer_for(active_token.name)

      within('#contextual-panel-portal') do
        expect(page).to have_text(active_token.name)
        expect(page).to have_text('Fine-grained token')
        expect(page).to have_text('Created on')
        expect(page).to have_text(active_token.description)
      end
    end

    it 'shows the expiry, last used, and IP usage fields' do
      open_drawer_for(active_token.name)

      within('#contextual-panel-portal') do
        expect(page).to have_text('Expires')
        expect(page).to have_text('Last used')
        expect(page).to have_text('IP Usage')
        expect(page).to have_text('No IP activity recorded yet.')
      end
    end

    it 'shows the scopes section with group and user permission counts' do
      open_drawer_for(active_token.name)

      within('#contextual-panel-portal') do
        expect(page).to have_text('Scopes')
        expect(page).to have_button('Group and project permissions (2)')
        expect(page).to have_button('User permissions (1)')
      end
    end

    it 'shows group and project access' do
      open_drawer_for(active_token.name)

      within('#contextual-panel-portal') do
        expect(page).to have_text('Group and project access')
        expect(page).to have_text("Only specific group or projects that I'm a member of")
        expect(page).to have_link(group.full_name, href: group.web_url)
      end
    end

    it 'shows revoke, rotate, and duplicate actions' do
      open_drawer_for(active_token.name)

      within('#contextual-panel-portal') do
        expect(page).to have_selector('[data-testid="revoke-token"]')
        expect(page).to have_selector('[data-testid="rotate-token"]')
        expect(page).to have_selector('[data-testid="duplicate-token"]')
      end
    end
  end

  def open_drawer_for(token_name)
    click_button token_name
  end
end
