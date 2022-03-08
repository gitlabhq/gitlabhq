# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Members > Manage members' do
  include Spec::Support::Helpers::Features::MembersHelpers
  include Spec::Support::Helpers::Features::InviteMembersModalHelper
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:user1) { create(:user, name: 'John Doe') }
  let_it_be(:user2) { create(:user, name: 'Mary Jane') }
  let_it_be(:group) { create(:group) }

  before do
    sign_in(user1)
  end

  shared_examples 'includes the correct Invite link' do |should_include|
    it 'includes the modal trigger', :aggregate_failures do
      group.add_owner(user1)

      visit group_group_members_path(group)

      expect(page).to have_selector(should_include)
    end
  end

  it_behaves_like 'includes the correct Invite link', '.js-invite-members-trigger'
  it_behaves_like 'includes the correct Invite link', '.js-invite-group-trigger'

  it 'update user to owner level', :js do
    group.add_owner(user1)
    group.add_developer(user2)

    visit group_group_members_path(group)

    page.within(second_row) do
      click_button('Developer')
      click_button('Owner')

      expect(page).to have_button('Owner')
    end
  end

  it 'add user to group', :js, :snowplow, :aggregate_failures do
    group.add_owner(user1)

    visit group_group_members_path(group)

    invite_member(user2.name, role: 'Reporter')

    page.within(second_row) do
      expect(page).to have_content(user2.name)
      expect(page).to have_button('Reporter')
    end

    expect_snowplow_event(
      category: 'Members::CreateService',
      action: 'create_member',
      label: 'group-members-page',
      property: 'existing_user',
      user: user1
    )
  end

  it 'do not disclose email addresses', :js do
    group.add_owner(user1)
    create(:user, email: 'undisclosed_email@gitlab.com', name: "Jane 'invisible' Doe")

    visit group_group_members_path(group)

    click_on 'Invite members'
    find('[data-testid="members-token-select-input"]').set('@gitlab.com')

    wait_for_requests

    expect(page).to have_content('No matches found')

    find('[data-testid="members-token-select-input"]').set('undisclosed_email@gitlab.com')
    wait_for_requests

    expect(page).to have_content('Invite "undisclosed_email@gitlab.com" by email')
  end

  it 'remove user from group', :js do
    group.add_owner(user1)
    group.add_developer(user2)

    visit group_group_members_path(group)

    # Open modal
    page.within(second_row) do
      click_button 'Remove member'
    end

    within_modal do
      expect(page).to have_unchecked_field 'Also unassign this user from related issues and merge requests'
      click_button('Remove member')
    end

    wait_for_requests

    aggregate_failures do
      expect(page).not_to have_content(user2.name)
      expect(group.users).not_to include(user2)
    end
  end

  it 'add yourself to group when already an owner', :js, :aggregate_failures do
    group.add_owner(user1)

    visit group_group_members_path(group)

    invite_member(user1.name, role: 'Reporter')

    page.within(first_row) do
      expect(page).to have_content(user1.name)
      expect(page).to have_content('Owner')
    end
  end

  it 'invite user to group', :js, :snowplow do
    group.add_owner(user1)

    visit group_group_members_path(group)

    invite_member('test@example.com', role: 'Reporter')

    expect(page).to have_link 'Invited'
    click_link 'Invited'

    aggregate_failures do
      page.within(members_table) do
        expect(page).to have_content('test@example.com')
        expect(page).to have_content('Invited')
        expect(page).to have_button('Reporter')
      end

      expect_snowplow_event(
        category: 'Members::InviteService',
        action: 'create_member',
        label: 'group-members-page',
        property: 'net_new_user',
        user: user1
      )
    end
  end

  context 'when user is a guest' do
    before do
      group.add_guest(user1)
      group.add_developer(user2)

      visit group_group_members_path(group)
    end

    it 'does not include either of the invite members or invite group modal buttons', :aggregate_failures do
      expect(page).not_to have_selector '.js-invite-members-modal'
      expect(page).not_to have_selector '.js-invite-group-modal'
    end

    it 'does not include a button on the members page list to manage or remove the existing member', :js, :aggregate_failures do
      page.within(second_row) do
        # Can not modify user2 role
        expect(page).not_to have_button 'Developer'

        # Can not remove user2
        expect(page).not_to have_selector 'button[title="Remove member"]'
      end
    end
  end
end
