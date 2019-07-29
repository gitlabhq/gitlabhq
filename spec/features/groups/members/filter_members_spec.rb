# frozen_string_literal: true

require 'spec_helper'

describe 'Groups > Members > Filter members' do
  let(:user)          { create(:user) }
  let(:user_with_2fa) { create(:user, :two_factor_via_otp) }
  let(:group)         { create(:group) }

  before do
    group.add_owner(user)
    group.add_maintainer(user_with_2fa)

    sign_in(user)
  end

  it 'shows all members' do
    visit_members_list

    expect(first_member).to include(user.name)
    expect(second_member).to include(user_with_2fa.name)
    expect(page).to have_css('.member-filter-2fa-dropdown .dropdown-toggle-text', text: '2FA: Everyone')
  end

  it 'shows only 2FA members' do
    visit_members_list(two_factor: 'enabled')

    expect(first_member).to include(user_with_2fa.name)
    expect(members_list.size).to eq(1)
    expect(page).to have_css('.member-filter-2fa-dropdown .dropdown-toggle-text', text: '2FA: Enabled')
  end

  it 'shows only non 2FA members' do
    visit_members_list(two_factor: 'disabled')

    expect(first_member).to include(user.name)
    expect(members_list.size).to eq(1)
    expect(page).to have_css('.member-filter-2fa-dropdown .dropdown-toggle-text', text: '2FA: Disabled')
  end

  def visit_members_list(options = {})
    visit group_group_members_path(group.to_param, options)
  end

  def members_list
    page.all('ul.content-list > li')
  end

  def first_member
    members_list.first.text
  end

  def second_member
    members_list.last.text
  end
end
