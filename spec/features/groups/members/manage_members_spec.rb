# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Members > Manage members', feature_category: :groups_and_projects do
  include ListboxHelpers
  include Features::MembersHelpers
  include Features::InviteMembersModalHelpers
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:user1) { create(:user, name: 'John Doe') }
  let_it_be(:user2) { create(:user, name: 'Mary Jane') }
  let_it_be(:group) { create(:group) }

  before do
    stub_feature_flags(show_role_details_in_drawer: false)
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
      select_from_listbox('Owner', from: 'Developer')

      expect(page).to have_button('Owner')
    end
  end

  it 'remove user from group', :js do
    group.add_owner(user1)
    group.add_developer(user2)

    visit group_group_members_path(group)

    # Open modal
    page.within(second_row) do
      show_actions
      click_button _('Remove member')
    end

    within_modal do
      expect(page).to have_unchecked_field 'Also unassign this user from related issues and merge requests'
      click_button _('Remove member')
    end

    wait_for_requests

    aggregate_failures do
      expect(page).not_to have_content(user2.name)
      expect(group).not_to have_user(user2)
    end
  end

  context 'when inviting' do
    it 'add yourself to group when already an owner', :js do
      group.add_owner(user1)

      visit group_group_members_path(group)

      invite_member(user1.name, role: 'Reporter')

      invite_modal = page.find(invite_modal_selector)
      expect(invite_modal).to have_content("not authorized to update member")

      page.refresh

      page.within find_member_row(user1) do
        expect(page).to have_content('Owner')
      end
    end

    it_behaves_like 'inviting members', 'group_members_page' do
      let_it_be(:entity) { group }
      let_it_be(:members_page_path) { group_group_members_path(entity) }
      let_it_be(:subentity) { create(:group, parent: group) }
      let_it_be(:subentity_members_page_path) { group_group_members_path(subentity) }
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

  describe 'member search results', :js do
    before do
      group.add_owner(user1)
    end

    it 'does not disclose email addresses' do
      create(:user, email: 'undisclosed_email@gitlab.com', name: "Jane 'invisible' Doe")

      visit group_group_members_path(group)

      click_on 'Invite members'
      find(member_dropdown_selector).set('@gitlab.com')

      wait_for_requests

      expect(page).to have_content('No matches found')

      find(member_dropdown_selector).set('undisclosed_email@gitlab.com')
      wait_for_requests

      expect(page).to have_content('Invite "undisclosed_email@gitlab.com" by email')
    end

    it 'does not show project_bots', :aggregate_failures do
      internal_project_bot = create(:user, :project_bot, name: '_internal_project_bot_')
      project = create(:project, group: group)
      project.add_maintainer(internal_project_bot)

      external_group = create(:group)
      external_project_bot = create(:user, :project_bot, name: '_external_project_bot_')
      external_project = create(:project, group: external_group)
      external_project.add_maintainer(external_project_bot)
      external_project.add_maintainer(user1)

      visit group_group_members_path(group)

      click_on 'Invite members'

      page.within invite_modal_selector do
        field = find(member_dropdown_selector)
        field.native.send_keys :tab
        field.click

        wait_for_requests

        expect(page).to have_content(user1.name)
        expect(page).to have_content(user2.name)
        expect(page).not_to have_content(internal_project_bot.name)
        expect(page).not_to have_content(external_project_bot.name)
      end
    end
  end
end
