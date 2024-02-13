# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Members > Leave group', feature_category: :groups_and_projects do
  include Features::MembersHelpers
  include Spec::Support::Helpers::ModalHelpers

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:group) { create(:group) }
  let(:more_actions_dropdown) do
    find('[data-testid="groups-projects-more-actions-dropdown"] .gl-new-dropdown-custom-toggle')
  end

  before do
    sign_in(user)
  end

  it 'guest leaves the group', :js do
    group.add_guest(user)
    group.add_owner(other_user)

    visit group_path(group)
    more_actions_dropdown.click
    click_link 'Leave group'
    accept_gl_confirm(button_text: 'Leave group')

    expect(page).to have_current_path(dashboard_groups_path, ignore_query: true)
    expect(page).to have_content left_group_message(group)
    expect(group).not_to have_user(user)
  end

  it 'guest leaves the group by url param', :js do
    group.add_guest(user)
    group.add_owner(other_user)

    visit group_path(group, leave: 1)
    accept_gl_confirm(button_text: 'Leave group')

    expect(page).to have_current_path(dashboard_groups_path, ignore_query: true)
    expect(group).not_to have_user(user)
  end

  it 'guest leaves the group as last member', :js do
    group.add_guest(user)

    visit group_path(group)
    more_actions_dropdown.click
    click_link 'Leave group'
    accept_gl_confirm(button_text: 'Leave group')

    expect(page).to have_current_path(dashboard_groups_path, ignore_query: true)
    expect(page).to have_content left_group_message(group)
    expect(group).not_to have_user(user)
  end

  it 'owner leaves the group if they are not the last owner', :js do
    group.add_owner(user)
    group.add_owner(other_user)

    visit group_path(group)
    more_actions_dropdown.click
    click_link 'Leave group'
    accept_gl_confirm(button_text: 'Leave group')

    expect(page).to have_current_path(dashboard_groups_path, ignore_query: true)
    expect(page).to have_content left_group_message(group)
    expect(group).not_to have_user(user)
  end

  it 'owner can not leave the group if they are the last owner', :js do
    group.add_owner(user)

    visit group_path(group)
    more_actions_dropdown.click

    expect(page).not_to have_content 'Leave group'

    visit group_group_members_path(group)

    expect(members_table).not_to have_selector 'button[title="Leave"]'
  end

  it 'owner can not leave the group by url param if they are the last owner', :js do
    group.add_owner(user)

    visit group_path(group, leave: 1)

    expect(find_by_testid('alert-danger')).to have_content 'You do not have permission to leave this group'
  end

  def left_group_message(group)
    "You left the \"#{group.name}\""
  end
end
