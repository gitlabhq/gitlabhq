# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Members > Filter members', :js, feature_category: :groups_and_projects do
  include Features::MembersHelpers

  let(:user)              { create(:user) }
  let(:nested_group_user) { create(:user) }
  let(:user_with_2fa)     { create(:user, :two_factor_via_otp) }
  let(:group)             { create(:group) }
  let(:nested_group)      { create(:group, parent: group) }

  filtered_search_bar_selector = '[data-testid="members-filtered-search-bar"]'

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
  end

  it 'shows only 2FA members' do
    visit_members_list(group, two_factor: 'enabled')

    expect(member(0)).to include(user_with_2fa.name)
    expect(all_rows.size).to eq(1)

    within filtered_search_bar_selector do
      expect(page).to have_content '2FA = Enabled'
    end
  end

  it 'shows only non 2FA members' do
    visit_members_list(group, two_factor: 'disabled')

    expect(member(0)).to include(user.name)
    expect(all_rows.size).to eq(1)

    within filtered_search_bar_selector do
      expect(page).to have_content '2FA = Disabled'
    end
  end

  it 'shows inherited members by default' do
    visit_members_list(nested_group)

    expect(member(0)).to include(user.name)
    expect(member(1)).to include(user_with_2fa.name)
    expect(member(2)).to include(nested_group_user.name)
    expect(all_rows.size).to eq(3)
  end

  it 'shows only group members' do
    visit_members_list(nested_group, with_inherited_permissions: 'exclude')
    expect(member(0)).to include(nested_group_user.name)
    expect(all_rows.size).to eq(1)

    within filtered_search_bar_selector do
      expect(page).to have_content 'Membership = Direct'
    end
  end

  it 'shows only indirect members' do
    visit_members_list(nested_group, with_inherited_permissions: 'only')
    expect(member(0)).to include(user.name)
    expect(member(1)).to include(user_with_2fa.name)
    expect(all_rows.size).to eq(2)

    within filtered_search_bar_selector do
      expect(page).to have_content 'Membership = Indirect'
    end
  end

  def visit_members_list(group, options = {})
    visit group_group_members_path(group.to_param, options)
  end

  def member(number)
    all_rows[number].text
  end
end
