# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Members > Manage groups', :js, feature_category: :groups_and_projects do
  include ListboxHelpers
  include Features::MembersHelpers
  include Features::InviteMembersModalHelpers
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:user) { create(:user) }

  before do
    stub_feature_flags(show_role_details_in_drawer: false)
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
        select_from_listbox('Maintainer', from: 'Developer')

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

          find_by_testid('clear-button').click

          wait_for_requests

          expect(page).to have_field('Expiration date', with: '')
        end
      end
    end
  end

  describe 'group search results' do
    let_it_be(:group, refind: true) { create(:group) }

    it_behaves_like 'inviting groups search results' do
      let_it_be(:entity) { group }
      let_it_be(:group_within_hierarchy) { create(:group, parent: group) }
      let_it_be(:members_page_path) { group_group_members_path(entity) }
      let_it_be(:members_page_path_within_hierarchy) { group_group_members_path(group_within_hierarchy) }
    end
  end
end
