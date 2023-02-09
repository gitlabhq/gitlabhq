# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profile > Notifications > List users saved replies', :js,
  feature_category: :user_profile do
  let_it_be(:user) { create(:user) }
  let_it_be(:saved_reply) { create(:saved_reply, user: user) }

  before do
    sign_in(user)
  end

  it 'shows the user a list of their saved replies' do
    visit profile_saved_replies_path

    expect(page).to have_content('My saved replies (1)')
    expect(page).to have_content(saved_reply.name)
    expect(page).to have_content(saved_reply.content)
  end
end
