# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard Group' do
  before do
    sign_in(create(:user))
  end

  it 'defaults sort dropdown to last created' do
    visit dashboard_groups_path

    expect(page).to have_button('Last created')
  end

  it 'creates new group', :js do
    visit dashboard_groups_path
    find('.btn-success').click
    new_name = 'Samurai'
    new_description = 'Tokugawa Shogunate'

    fill_in 'group_name', with: new_name
    fill_in 'group_description', with: new_description
    click_button 'Create group'

    expect(current_path).to eq group_path(Group.find_by(name: new_name))
    expect(page).to have_content(new_name)
    expect(page).to have_content(new_description)
  end
end
