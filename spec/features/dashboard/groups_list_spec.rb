require 'spec_helper'

describe 'Dashboard Groups page', js: true, feature: true do
  let!(:user) { create :user }
  let!(:group) { create(:group) }
  let!(:nested_group) { create(:group, :nested) }
  let!(:another_group) { create(:group) }

  before do
    group.add_owner(user)
    nested_group.add_owner(user)

    login_as(user)

    visit dashboard_groups_path
  end

  it 'shows groups user is member of' do
    expect(page).to have_content(group.full_name)
    expect(page).to have_content(nested_group.full_name)
    expect(page).not_to have_content(another_group.full_name)
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

    fill_in 'filter_groups', with: ""
    wait_for_requests

    expect(page).to have_content(group.full_name)
    expect(page).to have_content(nested_group.full_name)
    expect(page).not_to have_content(another_group.full_name)
    expect(page.all('.js-groups-list-holder .content-list li').length).to eq 2
  end
end
