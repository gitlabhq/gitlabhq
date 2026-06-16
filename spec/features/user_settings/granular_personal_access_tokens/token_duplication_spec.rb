# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User Settings > Granular personal access tokens > token duplication',
  :with_current_organization, :js, feature_category: :system_access do
  include Spec::Support::Helpers::ModalHelpers
  include ListboxHelpers

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

  before_all do
    group.add_owner(user)
  end

  before do
    stub_feature_flags(granular_personal_access_tokens: true)
    sign_in(user)
    visit user_settings_personal_access_tokens_path
  end

  it 'pre-fills the new form with the source token data' do
    open_row_actions(active_token.name)
    click_button 'Duplicate'

    within_modal { click_button 'Duplicate' }

    expect(page).to have_field('Name', with: "#{active_token.name} (copy)")
    expect(find_field('Description').value).to eq(active_token.description)
    expect(find_field('Expiration date').value).not_to be_empty

    expect(page).to have_checked_field("Only specific groups or projects that I'm a member of")

    within_testid('selected-namespaces') do
      expect(page).to have_text(group.full_path)
    end

    within(find_by_testid('selected-resource', text: 'Member Role')) do
      expect(page).to have_button('Read')
      expect(page).to have_button('Create')
    end

    page.within('.gl-tabs-nav') do
      click_on 'User'
    end

    within(find_by_testid('selected-resource', text: 'User')) do
      expect(page).to have_button('Read')
    end

    click_on 'Generate token'

    expect(page).to have_text('Your new token has been created')
  end

  def open_row_actions(token_name)
    row = find('tr', text: token_name)
    within(row) { click_button 'Actions' }
  end
end
