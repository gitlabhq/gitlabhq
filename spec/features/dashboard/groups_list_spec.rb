# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard Groups page', :js, feature_category: :groups_and_projects do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:nested_group) { create(:group, :nested) }
  let(:another_group) { create(:group) }

  def click_group_caret(group)
    within("#group-#{group.id}") do
      find_by_testid('group-item-toggle-button').click
    end
    wait_for_requests
  end

  def click_options_menu(group)
    page.find("[data-testid='group-#{group.id}-dropdown-button'").click
  end

  it_behaves_like 'a "Your work" page with sidebar and breadcrumbs', :dashboard_groups_path, :groups

  it 'shows groups user is member of' do
    group.add_owner(user)
    nested_group.add_owner(user)
    expect(another_group).to be_persisted

    sign_in(user)
    visit dashboard_groups_path
    wait_for_requests

    expect(page).to have_content(group.name)

    expect(page).not_to have_content(another_group.name)
  end

  it 'shows subgroups the user is member of' do
    group.add_owner(user)
    nested_group.add_owner(user)

    sign_in(user)
    visit dashboard_groups_path
    wait_for_requests

    expect(page).to have_content(nested_group.parent.name)
    click_group_caret(nested_group.parent)
    expect(page).to have_content(nested_group.name)
  end

  context 'when filtering groups' do
    before do
      group.add_owner(user)
      nested_group.add_owner(user)
      expect(another_group).to be_persisted

      sign_in(user)

      visit dashboard_groups_path
    end

    it 'expands when filtering groups' do
      search(nested_group.name)
      wait_for_requests

      expect(page).not_to have_content(group.name)
      expect(page).to have_content(nested_group.parent.name)
      expect(page).to have_content(nested_group.name)
      expect(page).not_to have_content(another_group.name)
    end

    it 'resets search when user cleans the input' do
      search(group.name)
      wait_for_requests

      expect(page).to have_content(group.name)
      expect(page).not_to have_content(nested_group.parent.name)

      find_by_testid('filtered-search-clear-button').click
      wait_for_requests

      expect(page).to have_content(group.name)
      expect(page).to have_content(nested_group.parent.name)
      expect(page).not_to have_content(another_group.name)
      within find_by_testid('groups-list-tree-container') do
        expect(find_all('li').length).to eq 2
      end
    end
  end

  context 'with subgroups' do
    let!(:subgroup) { create(:group, :public, parent: group) }

    before do
      group.add_owner(user)
      subgroup.add_owner(user)

      sign_in(user)

      visit dashboard_groups_path
    end

    it 'shows subgroups inside of its parent group' do
      expect(page).to have_selector("#group-#{group.id}")
      click_group_caret(group)
      expect(page).to have_selector("#group-#{group.id} #group-#{subgroup.id}")
    end

    it 'can toggle parent group' do
      # expand
      click_group_caret(group)

      expect(page).to have_selector("#group-#{group.id} #group-#{subgroup.id}")

      # collapse
      click_group_caret(group)

      expect(page).not_to have_selector("#group-#{group.id} #group-#{subgroup.id}")
    end
  end

  context 'group actions dropdown' do
    let!(:subgroup) { create(:group, :public, parent: group) }

    context 'user with subgroup ownership' do
      before do
        subgroup.add_owner(user)
        sign_in(user)

        visit dashboard_groups_path
      end

      it 'cannot remove parent group' do
        expect(page).not_to have_selector("[data-testid='group-#{group.id}-dropdown-button'")
      end
    end

    context 'user with parent group ownership' do
      before do
        group.add_owner(user)
        sign_in(user)

        visit dashboard_groups_path
      end

      it 'can remove parent group' do
        click_options_menu(group)

        expect(page).to have_selector("[data-testid='remove-group-#{group.id}-btn']")
      end

      it 'can remove subgroups' do
        click_group_caret(group)
        click_options_menu(subgroup)

        expect(page).to have_selector("[data-testid='remove-group-#{subgroup.id}-btn']")
      end
    end

    context 'user is a maintainer' do
      before do
        group.add_maintainer(user)
        sign_in(user)

        visit dashboard_groups_path
        click_options_menu(group)
      end

      it 'cannot remove the group' do
        expect(page).not_to have_selector("[data-testid='remove-group-#{group.id}-btn']")
      end

      it 'cannot edit the group' do
        expect(page).not_to have_selector("[data-testid='edit-group-#{group.id}-btn']")
      end

      it 'can leave the group' do
        expect(page).to have_selector("[data-testid='leave-group-#{group.id}-btn']")
      end
    end
  end

  context 'when using pagination' do
    let(:group)  { create(:group, created_at: 5.days.ago) }
    let(:group2) { create(:group, created_at: 2.days.ago) }

    before do
      group.add_owner(user)
      group2.add_owner(user)

      allow(Kaminari.config).to receive(:default_per_page).and_return(1)

      sign_in(user)
      visit dashboard_groups_path
    end

    it 'loads results for next page' do
      expect(page).to have_selector('[data-testid="gl-pagination-item"]', count: 2)
      expect(page).to have_selector('[data-testid="gl-pagination-next"]')

      # Check first page
      expect(page).to have_content(group2.full_name)
      expect(page).to have_selector("#group-#{group2.id}")
      expect(page).not_to have_content(group.full_name)
      expect(page).not_to have_selector("#group-#{group.id}")

      # Go to next page
      find_by_testid('gl-pagination-next').click

      wait_for_requests

      # Check second page
      expect(page).to have_content(group.full_name)
      expect(page).to have_selector("#group-#{group.id}")
      expect(page).not_to have_content(group2.full_name)
      expect(page).not_to have_selector("#group-#{group2.id}")
    end
  end

  context 'when signed in as admin' do
    let(:admin) { create(:admin) }

    it 'shows only groups admin is member of' do
      group.add_owner(admin)
      expect(another_group).to be_persisted

      sign_in(admin)
      visit dashboard_groups_path
      wait_for_requests

      expect(page).to have_content(group.name)
      expect(page).not_to have_content(another_group.name)
    end
  end

  it 'links to the "Explore groups" page' do
    sign_in(user)
    visit dashboard_groups_path

    expect(page).to have_link("Explore groups", href: explore_groups_path)
  end

  context 'when there are no groups to display' do
    before do
      sign_in(user)
      visit dashboard_groups_path
    end

    it 'shows empty state' do
      expect(page).to have_content(s_('GroupsEmptyState|A group is a collection of several projects'))
    end
  end

  def search(term)
    filter_input = find_by_testid('filtered-search-term-input')
    filter_input.click
    filter_input.set(term)
    click_button 'Search'
  end
end
