# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard Group', feature_category: :groups_and_projects do
  before do
    sign_in(create(:user))
  end

  it 'shows empty state', :js do
    visit dashboard_groups_path

    expect(page).to have_selector('[data-testid="groups-empty-state"]')
  end

  it 'creates new group', :js do
    visit dashboard_groups_path
    click_link 'New group'
    click_link 'Create group'

    new_name = 'Samurai'

    fill_in 'group_name', with: new_name
    click_button 'Create group'

    expect(page).to have_current_path group_path(Group.find_by(name: new_name)), ignore_query: true
    expect(page).to have_content(new_name)
  end

  it 'defaults sort dropdown to last created' do
    user = create(:user)
    group = create(:group)
    group.add_owner(user)
    sign_in(user)
    visit dashboard_groups_path

    expect(page).to have_selector('[data-testid="group_sort_by_dropdown"]')
  end
end
