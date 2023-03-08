# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profile > Saved replies > User updated saved reply', :js,
  feature_category: :user_profile do
  let_it_be(:user) { create(:user) }
  let_it_be(:saved_reply) { create(:saved_reply, user: user) }

  before do
    sign_in(user)

    visit profile_saved_replies_path

    wait_for_requests
  end

  it 'shows the user a list of their saved replies' do
    find('[data-testid="saved-reply-edit-btn"]').click
    find('[data-testid="saved-reply-name-input"]').set('test')

    click_button 'Save'

    wait_for_requests

    expect(page).to have_selector('[data-testid="saved-reply-name"]', text: 'test')
  end
end
