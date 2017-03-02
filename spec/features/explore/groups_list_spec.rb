require 'spec_helper'

describe 'Explore Groups page', js: true, feature: true do
  include WaitForAjax

  let!(:user) { create :user }
  let!(:group) { create(:group) }
  let!(:public_group) { create(:group, :public) }
  let!(:private_group) { create(:group, :private) }

  before do
    group.add_owner(user)

    login_as(user)

    visit explore_groups_path
  end

  it 'shows groups user is member of' do
    expect(page).to have_content(group.full_name)
    expect(page).to have_content(public_group.full_name)
    expect(page).not_to have_content(private_group.full_name)
  end

  it 'filters groups' do
    fill_in 'filter_groups', with: group.name
    wait_for_ajax

    expect(page).to have_content(group.full_name)
    expect(page).not_to have_content(public_group.full_name)
    expect(page).not_to have_content(private_group.full_name)
  end

  it 'resets search when user cleans the input' do
    fill_in 'filter_groups', with: group.name
    wait_for_ajax

    fill_in 'filter_groups', with: ""
    wait_for_ajax

    expect(page).to have_content(group.full_name)
    expect(page).to have_content(public_group.full_name)
    expect(page).not_to have_content(private_group.full_name)
    expect(page.all('.js-groups-list-holder .content-list li').length).to eq 2
  end
end
