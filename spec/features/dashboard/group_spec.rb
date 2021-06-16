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
    find('[data-testid="new-group-button"]').click
    click_link 'Create group'

    new_name = 'Samurai'

    fill_in 'group_name', with: new_name
    click_button 'Create group'

    expect(current_path).to eq group_path(Group.find_by(name: new_name))
    expect(page).to have_content(new_name)
  end
end
