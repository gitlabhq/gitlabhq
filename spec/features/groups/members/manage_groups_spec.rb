# frozen_string_literal: true

require 'spec_helper'

describe 'Groups > Members > Manage groups', :js do
  include Select2Helper
  include Spec::Support::Helpers::Features::ListRowsHelpers

  let(:user) { create(:user) }
  let(:shared_with_group) { create(:group) }
  let(:shared_group) { create(:group) }

  before do
    shared_group.add_owner(user)
    sign_in(user)
  end

  context 'with share groups with groups feature flag' do
    before do
      stub_feature_flags(shared_with_group: true)
    end

    it 'add group to group' do
      visit group_group_members_path(shared_group)

      add_group(shared_with_group.id, 'Reporter')

      page.within(first_row) do
        expect(page).to have_content(shared_with_group.name)
        expect(page).to have_content('Reporter')
      end
    end

    it 'remove user from group' do
      create(:group_group_link, shared_group: shared_group,
        shared_with_group: shared_with_group, group_access: ::Gitlab::Access::DEVELOPER)

      visit group_group_members_path(shared_group)

      expect(page).to have_content(shared_with_group.name)

      accept_confirm do
        find(:css, '#existing_shares li', text: shared_with_group.name).find(:css, 'a.btn-remove').click
      end

      wait_for_requests

      expect(page).not_to have_content(shared_with_group.name)
    end

    it 'update group to owner level' do
      create(:group_group_link, shared_group: shared_group,
        shared_with_group: shared_with_group, group_access: ::Gitlab::Access::DEVELOPER)

      visit group_group_members_path(shared_group)

      page.within(first_row) do
        click_button('Developer')
        click_link('Maintainer')

        wait_for_requests

        expect(page).to have_button('Maintainer')
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
  end

  context 'without share groups with groups feature flag' do
    before do
      stub_feature_flags(share_group_with_group: false)
    end

    it 'does not render invitation form and tabs' do
      visit group_group_members_path(shared_group)

      expect(page).not_to have_link('Invite member')
      expect(page).not_to have_link('Invite group')
    end
  end
end
