# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > Groups with access list', :js do
  include Spec::Support::Helpers::Features::MembersHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public) }

  let(:additional_link_attrs) { {} }
  let!(:group_link) { create(:project_group_link, project: project, group: group, **additional_link_attrs) }

  before do
    travel_to Time.now.utc.beginning_of_day

    project.add_maintainer(user)
    sign_in(user)
  end

  context 'when `vue_project_members_list` feature flag is enabled' do
    before do
      visit project_project_members_path(project)
      click_groups_tab
    end

    it 'updates group access level' do
      click_button group_link.human_access
      click_button 'Guest'

      wait_for_requests

      visit project_project_members_path(project)

      click_groups_tab

      expect(find_group_row(group)).to have_content('Guest')
    end

    it 'updates expiry date' do
      page.within find_group_row(group) do
        fill_in 'Expiration date', with: 5.days.from_now.to_date
        find_field('Expiration date').native.send_keys :enter

        wait_for_requests

        expect(page).to have_content(/in \d days/)
      end
    end

    context 'when link has expiry date set' do
      let(:additional_link_attrs) { { expires_at: 5.days.from_now.to_date } }

      it 'clears expiry date' do
        page.within find_group_row(group) do
          expect(page).to have_content(/in \d days/)

          find('[data-testid="clear-button"]').click

          wait_for_requests

          expect(page).to have_content('No expiration set')
        end
      end
    end

    it 'deletes group link' do
      expect(page).to have_content(group.full_name)

      page.within find_group_row(group) do
        click_button 'Remove group'
      end

      page.within('[role="dialog"]') do
        click_button('Remove group')
      end

      expect(page).not_to have_content(group.full_name)
    end

    context 'search in existing members' do
      it 'finds no results' do
        fill_in_filtered_search 'Search groups', with: 'testing 123'

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

  context 'when `vue_project_members_list` feature flag is disabled' do
    before do
      stub_feature_flags(vue_project_members_list: false)

      visit project_project_members_path(project)
      click_groups_tab
    end

    it 'updates group access level' do
      click_button group_link.human_access

      page.within '.dropdown-menu' do
        click_link 'Guest'
      end

      wait_for_requests

      visit project_project_members_path(project)

      click_groups_tab

      expect(first('.group_member')).to have_content('Guest')
    end

    it 'updates expiry date' do
      expires_at_field = "member_expires_at_#{group.id}"
      fill_in expires_at_field, with: 3.days.from_now.to_date

      find_field(expires_at_field).native.send_keys :enter
      wait_for_requests

      page.within(find('li.group_member')) do
        expect(page).to have_content('Expires in 3 days')
      end
    end

    context 'when link has expiry date set' do
      let(:additional_link_attrs) { { expires_at: 3.days.from_now.to_date } }

      it 'clears expiry date' do
        page.within(find('li.group_member')) do
          expect(page).to have_content('Expires in 3 days')

          page.within(find('.js-edit-member-form')) do
            find('.js-clear-input').click
          end

          wait_for_requests

          expect(page).not_to have_content('Expires in')
        end
      end
    end

    it 'deletes group link' do
      page.within(first('.group_member')) do
        accept_confirm { find('.btn-danger').click }
      end
      wait_for_requests

      expect(page).not_to have_selector('.group_member')
    end

    context 'search in existing members' do
      it 'finds no results' do
        page.within '.user-search-form' do
          fill_in 'search_groups', with: 'testing 123'
          find('.user-search-btn').click
        end

        click_groups_tab

        expect(page).not_to have_selector('.group_member')
      end

      it 'finds results' do
        page.within '.user-search-form' do
          fill_in 'search_groups', with: group.name
          find('.user-search-btn').click
        end

        click_groups_tab

        expect(page).to have_selector('.group_member', count: 1)
      end
    end
  end

  def click_groups_tab
    click_link 'Groups'
  end
end
