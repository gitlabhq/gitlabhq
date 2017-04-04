require 'spec_helper'

RSpec.describe 'Dashboard Group', feature: true do
  before do
    login_as(:user)
  end

  it 'creates new grpup' do
    visit dashboard_groups_path
    click_link 'New Group'

    fill_in 'group_path', with: 'Samurai'
    fill_in 'group_description', with: 'Tokugawa Shogunate'
    click_button 'Create group'

    expect(current_path).to eq group_path(Group.find_by(name: 'Samurai'))
    expect(page).to have_content('Samurai')
    expect(page).to have_content('Tokugawa Shogunate')
  end
end
