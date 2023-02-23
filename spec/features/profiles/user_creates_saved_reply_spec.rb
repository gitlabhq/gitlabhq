# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profile > Saved replies > User creates saved reply', :js,
  feature_category: :user_profile do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)

    visit profile_saved_replies_path

    wait_for_requests
  end

  it 'shows the user a list of their saved replies' do
    find('[data-testid="saved-reply-name-input"]').set('test')
    find('[data-testid="saved-reply-content-input"]').set('Test content')

    click_button 'Save'

    wait_for_requests

    expect(page).to have_content('My saved replies (1)')
    expect(page).to have_content('test')
    expect(page).to have_content('Test content')
  end
end
