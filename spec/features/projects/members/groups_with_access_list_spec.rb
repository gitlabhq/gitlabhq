# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > Groups with access list', :js, feature_category: :groups_and_projects do
  include ListboxHelpers
  include Features::MembersHelpers
  include Spec::Support::Helpers::ModalHelpers
  include Features::InviteMembersModalHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, :with_namespace_settings) }
  let_it_be(:expiration_date) { 5.days.from_now.to_date }

  let(:additional_link_attrs) { {} }
  let!(:group_link) { create(:project_group_link, project: project, group: group, **additional_link_attrs) }

  before do
    travel_to Time.now.utc.beginning_of_day
    stub_feature_flags(show_role_details_in_drawer: false)

    project.add_maintainer(user)
    sign_in(user)

    visit project_project_members_path(project)
    click_groups_tab
  end

  it 'updates group access level' do
    select_from_listbox('Guest', from: group_link.human_access)

    wait_for_requests

    visit project_project_members_path(project)

    click_groups_tab

    expect(find_group_row(group)).to have_content('Guest')
  end

  it 'updates expiry date' do
    page.within find_group_row(group) do
      fill_in 'Expiration date', with: expiration_date
      find_field('Expiration date').native.send_keys :enter

      wait_for_requests

      expect(page).to have_field('Expiration date', with: expiration_date)
    end
  end

  context 'when link has expiry date set' do
    let(:additional_link_attrs) { { expires_at: expiration_date } }

    it 'clears expiry date' do
      page.within find_group_row(group) do
        expect(page).to have_field('Expiration date', with: expiration_date)

        find_by_testid('clear-button').click

        wait_for_requests

        expect(page).to have_field('Expiration date', with: '')
      end
    end
  end

  it 'deletes group link' do
    expect(page).to have_content(group.full_name)

    page.within find_group_row(group) do
      click_button 'Remove group'
    end

    within_modal do
      click_button('Remove group')
    end

    expect(page).not_to have_content(group.full_name)
  end

  context 'search in existing members' do
    it 'finds no results' do
      fill_in_filtered_search 'Search groups', with: 'non_existing_group_name'

      click_groups_tab

      expect(page).not_to have_content(group.full_name)
    end

    it 'finds results' do
      fill_in_filtered_search 'Search groups', with: group.full_name

      click_groups_tab

      expect(members_table).to have_content(group.full_name)
    end
  end
end
