# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Members > Manage groups', :js do
  include Spec::Support::Helpers::Features::MembersHelpers
  include Spec::Support::Helpers::Features::InviteMembersModalHelper
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  context 'when group link does not exist' do
    it 'can share a group with group' do
      group = create(:group)
      group_to_add = create(:group)
      group.add_owner(user)
      group_to_add.add_owner(user)

      visit group_group_members_path(group)
      invite_group(group_to_add.name, role: 'Reporter')

      click_groups_tab

      page.within(first_row) do
        expect(page).to have_content(group_to_add.name)
        expect(page).to have_content('Reporter')
      end
    end
  end

  context 'when group link exists' do
    let_it_be(:shared_with_group) { create(:group) }
    let_it_be(:shared_group) { create(:group) }
    let_it_be(:expiration_date) { 5.days.from_now.to_date }

    let(:additional_link_attrs) { {} }

    let_it_be(:group_link, refind: true) do
      create(
        :group_group_link,
        shared_group: shared_group,
        shared_with_group: shared_with_group,
        group_access: ::Gitlab::Access::DEVELOPER
      )
    end

    before do
      group_link.update!(additional_link_attrs)

      shared_group.add_owner(user)
      visit group_group_members_path(shared_group)
    end

    it 'remove group from group' do
      click_groups_tab

      expect(page).to have_content(shared_with_group.name)

      page.within(first_row) do
        click_button 'Remove group'
      end

      within_modal do
        click_button('Remove group')
      end

      expect(page).not_to have_content(shared_with_group.name)
    end

    it 'update group to owner level' do
      click_groups_tab

      page.within(first_row) do
        click_button('Developer')
        click_button('Maintainer')

        wait_for_requests

        expect(page).to have_button('Maintainer')
      end
    end

    it 'updates expiry date' do
      click_groups_tab

      page.within first_row do
        fill_in 'Expiration date', with: expiration_date
        find_field('Expiration date').native.send_keys :enter

        wait_for_requests

        expect(page).to have_field('Expiration date', with: expiration_date)
      end
    end

    context 'when expiry date is set' do
      let(:additional_link_attrs) { { expires_at: expiration_date } }

      it 'clears expiry date' do
        click_groups_tab

        page.within first_row do
          expect(page).to have_field('Expiration date', with: expiration_date)

          find('[data-testid="clear-button"]').click

          wait_for_requests

          expect(page).to have_field('Expiration date', with: '')
        end
      end
    end
  end

  describe 'group search results' do
    let_it_be(:group, refind: true) { create(:group) }

    context 'with instance admin considerations' do
      let_it_be(:group_to_share) { create(:group) }

      context 'when user is an admin' do
        let_it_be(:admin) { create(:admin) }

        before do
          sign_in(admin)
          gitlab_enable_admin_mode_sign_in(admin)
        end

        it 'shows groups where the admin has no direct membership' do
          visit group_group_members_path(group)

          click_on 'Invite a group'
          click_on 'Select a group'
          wait_for_requests

          page.within(group_dropdown_selector) do
            expect_to_have_group(group_to_share)
            expect_not_to_have_group(group)
          end
        end

        it 'shows groups where the admin has at least guest level membership' do
          group_to_share.add_guest(admin)

          visit group_group_members_path(group)

          click_on 'Invite a group'
          click_on 'Select a group'
          wait_for_requests

          page.within(group_dropdown_selector) do
            expect_to_have_group(group_to_share)
            expect_not_to_have_group(group)
          end
        end
      end

      context 'when user is not an admin' do
        before do
          group.add_owner(user)
        end

        it 'shows groups where the user has no direct membership' do
          visit group_group_members_path(group)

          click_on 'Invite a group'
          click_on 'Select a group'
          wait_for_requests

          page.within(group_dropdown_selector) do
            expect_not_to_have_group(group_to_share)
            expect_not_to_have_group(group)
          end
        end

        it 'shows groups where the user has at least guest level membership' do
          group_to_share.add_guest(user)

          visit group_group_members_path(group)

          click_on 'Invite a group'
          click_on 'Select a group'
          wait_for_requests

          page.within(group_dropdown_selector) do
            expect_to_have_group(group_to_share)
            expect_not_to_have_group(group)
          end
        end
      end
    end

    context 'when user is not an admin and there are hierarchy considerations' do
      let_it_be(:group_within_hierarchy) { create(:group, parent: group) }
      let_it_be(:group_outside_hierarchy) { create(:group) }

      before_all do
        group.add_owner(user)
        group_within_hierarchy.add_owner(user)
        group_outside_hierarchy.add_owner(user)
      end

      it 'does not show self or ancestors', :aggregate_failures do
        group_sibbling = create(:group, parent: group)
        group_sibbling.add_owner(user)

        visit group_group_members_path(group_within_hierarchy)

        click_on 'Invite a group'
        click_on 'Select a group'
        wait_for_requests

        page.within(group_dropdown_selector) do
          expect_to_have_group(group_outside_hierarchy)
          expect_to_have_group(group_sibbling)
          expect_not_to_have_group(group)
          expect_not_to_have_group(group_within_hierarchy)
        end
      end

      context 'when sharing with groups outside the hierarchy is enabled' do
        it 'shows groups within and outside the hierarchy in search results' do
          visit group_group_members_path(group)

          click_on 'Invite a group'
          click_on 'Select a group'
          wait_for_requests

          page.within(group_dropdown_selector) do
            expect_to_have_group(group_within_hierarchy)
            expect_to_have_group(group_outside_hierarchy)
          end
        end
      end

      context 'when sharing with groups outside the hierarchy is disabled' do
        before do
          group.namespace_settings.update!(prevent_sharing_groups_outside_hierarchy: true)
        end

        it 'shows only groups within the hierarchy in search results' do
          visit group_group_members_path(group)

          click_on 'Invite a group'
          click_on 'Select a group'

          page.within(group_dropdown_selector) do
            expect_to_have_group(group_within_hierarchy)
            expect_not_to_have_group(group_outside_hierarchy)
          end
        end
      end
    end
  end
end
