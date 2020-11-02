# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Members > Filter members', :js do
  include Spec::Support::Helpers::Features::MembersHelpers

  let(:user)              { create(:user) }
  let(:nested_group_user) { create(:user) }
  let(:user_with_2fa)     { create(:user, :two_factor_via_otp) }
  let(:group)             { create(:group) }
  let(:nested_group)      { create(:group, parent: group) }

  two_factor_auth_dropdown_toggle_selector = '[data-testid="member-filter-2fa-dropdown"] [data-testid="dropdown-toggle"]'
  active_inherited_members_filter_selector = '[data-testid="filter-members-with-inherited-permissions"] a.is-active'

  before do
    group.add_owner(user)
    group.add_maintainer(user_with_2fa)
    nested_group.add_maintainer(nested_group_user)

    sign_in(user)
  end

  it 'shows all members' do
    visit_members_list(group)

    expect(member(0)).to include(user.name)
    expect(member(1)).to include(user_with_2fa.name)
    expect(page).to have_css(two_factor_auth_dropdown_toggle_selector, text: 'Everyone')
  end

  it 'shows only 2FA members' do
    visit_members_list(group, two_factor: 'enabled')

    expect(member(0)).to include(user_with_2fa.name)
    expect(all_rows.size).to eq(1)
    expect(page).to have_css(two_factor_auth_dropdown_toggle_selector, text: 'Enabled')
  end

  it 'shows only non 2FA members' do
    visit_members_list(group, two_factor: 'disabled')

    expect(member(0)).to include(user.name)
    expect(all_rows.size).to eq(1)
    expect(page).to have_css(two_factor_auth_dropdown_toggle_selector, text: 'Disabled')
  end

  it 'shows inherited members by default' do
    visit_members_list(nested_group)

    expect(member(0)).to include(user.name)
    expect(member(1)).to include(user_with_2fa.name)
    expect(member(2)).to include(nested_group_user.name)
    expect(all_rows.size).to eq(3)

    expect(page).to have_css(active_inherited_members_filter_selector, text: 'Show all members', visible: false)
  end

  it 'shows only group members' do
    visit_members_list(nested_group, with_inherited_permissions: 'exclude')
    expect(member(0)).to include(nested_group_user.name)
    expect(all_rows.size).to eq(1)
    expect(page).to have_css(active_inherited_members_filter_selector, text: 'Show only direct members', visible: false)
  end

  it 'shows only inherited members' do
    visit_members_list(nested_group, with_inherited_permissions: 'only')
    expect(member(0)).to include(user.name)
    expect(member(1)).to include(user_with_2fa.name)
    expect(all_rows.size).to eq(2)
    expect(page).to have_css(active_inherited_members_filter_selector, text: 'Show only inherited members', visible: false)
  end

  def visit_members_list(group, options = {})
    visit group_group_members_path(group.to_param, options)
  end

  def member(number)
    all_rows[number].text
  end
end
