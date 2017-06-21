require 'spec_helper'

RSpec.describe 'Dashboard Group', feature: true do
  before do
    sign_in(create(:user))
  end

  it 'creates new group', js: true do
    visit dashboard_groups_path
    find('.btn-new').trigger('click')
    new_path = 'Samurai'
    new_description = 'Tokugawa Shogunate'

    fill_in 'group_path', with: new_path
    fill_in 'group_description', with: new_description
    click_button 'Create group'

    expect(current_path).to eq group_path(Group.find_by(name: new_path))
    expect(page).to have_content(new_path)
    expect(page).to have_content(new_description)
  end
end
