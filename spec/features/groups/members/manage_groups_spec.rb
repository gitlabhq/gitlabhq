# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Members > Manage groups', :js do
  include Select2Helper
  include Spec::Support::Helpers::Features::MembersHelpers
  include Spec::Support::Helpers::Features::InviteMembersModalHelper

  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  context 'with invite_members_group_modal disabled' do
    before do
      stub_feature_flags(invite_members_group_modal: false)
    end

    context 'when group link does not exist' do
      let_it_be(:group) { create(:group) }
      let_it_be(:group_to_add) { create(:group) }

      before do
        group.add_owner(user)
        group_to_add.add_owner(user)
        visit group_group_members_path(group)
      end

      it 'can share group with group' do
        add_group(group_to_add.id, 'Reporter')

        click_groups_tab

        page.within(first_row) do
          expect(page).to have_content(group_to_add.name)
          expect(page).to have_content('Reporter')
        end
      end
    end
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

      page.within('[role="dialog"]') do
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
        fill_in 'Expiration date', with: 5.days.from_now.to_date
        find_field('Expiration date').native.send_keys :enter

        wait_for_requests

        expect(page).to have_content(/in \d days/)
      end
    end

    context 'when expiry date is set' do
      let(:additional_link_attrs) { { expires_at: 5.days.from_now.to_date } }

      it 'clears expiry date' do
        click_groups_tab

        page.within first_row do
          expect(page).to have_content(/in \d days/)

          find('[data-testid="clear-button"]').click

          wait_for_requests

          expect(page).to have_content('No expiration set')
        end
      end
    end
  end

  def add_group(id, role)
    page.click_link 'Invite group'
    page.within ".invite-group-form" do
      select2(id, from: "#shared_with_group_id")
      select(role, from: "shared_group_access")
      click_button "Invite"
    end
  end

  def click_groups_tab
    expect(page).to have_link 'Groups'
    click_link "Groups"
  end
end
