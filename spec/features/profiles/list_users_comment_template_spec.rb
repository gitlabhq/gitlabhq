# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profile > Comment templates > List users comment templates', :js,
  feature_category: :user_profile do
  let_it_be(:user) { create(:user) }
  let_it_be(:saved_reply) { create(:saved_reply, user: user) }

  before do
    sign_in(user)
  end

  it 'shows the user a list of their comment templates' do
    visit profile_comment_templates_path

    expect(page).to have_content('Comment templates')
    expect(page).to have_content(saved_reply.name)
    expect(page).to have_content(saved_reply.content)
  end
end
