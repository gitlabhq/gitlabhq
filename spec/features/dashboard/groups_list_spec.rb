require 'spec_helper'

feature 'Dashboard Groups page', :js do
  let!(:user) { create :user }
  let!(:group) { create(:group) }
  let!(:nested_group) { create(:group, :nested) }
  let!(:another_group) { create(:group) }

  it 'shows groups user is member of' do
    group.add_owner(user)
    nested_group.add_owner(user)

    sign_in(user)
    visit dashboard_groups_path

    expect(page).to have_content(group.full_name)
    expect(page).to have_content(nested_group.full_name)
    expect(page).not_to have_content(another_group.full_name)
  end

  describe 'when filtering groups' do
    before do
      group.add_owner(user)
      nested_group.add_owner(user)

      sign_in(user)

      visit dashboard_groups_path
    end

    it 'filters groups' do
      fill_in 'filter_groups', with: group.name
      wait_for_requests

      expect(page).to have_content(group.full_name)
      expect(page).not_to have_content(nested_group.full_name)
      expect(page).not_to have_content(another_group.full_name)
    end

    it 'resets search when user cleans the input' do
      fill_in 'filter_groups', with: group.name
      wait_for_requests

      fill_in 'filter_groups', with: ''
      wait_for_requests

      expect(page).to have_content(group.full_name)
      expect(page).to have_content(nested_group.full_name)
      expect(page).not_to have_content(another_group.full_name)
      expect(page.all('.js-groups-list-holder .content-list li').length).to eq 2
    end
  end

  describe 'group with subgroups' do
    let!(:subgroup) { create(:group, :public, parent: group) }

    before do
      group.add_owner(user)
      subgroup.add_owner(user)

      sign_in(user)

      visit dashboard_groups_path
    end

    it 'shows subgroups inside of its parent group' do
      expect(page).to have_selector('.groups-list-tree-container .group-list-tree', count: 2)
      expect(page).to have_selector(".groups-list-tree-container #group-#{group.id} #group-#{subgroup.id}", count: 1)
    end

    it 'can toggle parent group' do
      # Expanded by default
      expect(page).to have_selector("#group-#{group.id} .fa-caret-down", count: 1)
      expect(page).not_to have_selector("#group-#{group.id} .fa-caret-right")

      # Collapse
      find("#group-#{group.id}").trigger('click')

      expect(page).not_to have_selector("#group-#{group.id} .fa-caret-down")
      expect(page).to have_selector("#group-#{group.id} .fa-caret-right", count: 1)
      expect(page).not_to have_selector("#group-#{group.id} #group-#{subgroup.id}")

      # Expand
      find("#group-#{group.id}").trigger('click')

      expect(page).to have_selector("#group-#{group.id} .fa-caret-down", count: 1)
      expect(page).not_to have_selector("#group-#{group.id} .fa-caret-right")
      expect(page).to have_selector("#group-#{group.id} #group-#{subgroup.id}")
    end
  end

  describe 'when using pagination' do
    let(:group2) { create(:group) }

    before do
      group.add_owner(user)
      group2.add_owner(user)

      allow(Kaminari.config).to receive(:default_per_page).and_return(1)

      sign_in(user)
      visit dashboard_groups_path
    end

    it 'shows pagination' do
      expect(page).to have_selector('.gl-pagination')
      expect(page).to have_selector('.gl-pagination .page', count: 2)
    end

    it 'loads results for next page' do
      # Check first page
      expect(page).to have_content(group2.full_name)
      expect(page).to have_selector("#group-#{group2.id}")
      expect(page).not_to have_content(group.full_name)
      expect(page).not_to have_selector("#group-#{group.id}")

      # Go to next page
      find(".gl-pagination .page:not(.active) a").trigger('click')

      wait_for_requests

      # Check second page
      expect(page).to have_content(group.full_name)
      expect(page).to have_selector("#group-#{group.id}")
      expect(page).not_to have_content(group2.full_name)
      expect(page).not_to have_selector("#group-#{group2.id}")
    end
  end
end
