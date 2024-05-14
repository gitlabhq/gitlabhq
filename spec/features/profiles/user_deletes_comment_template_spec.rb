# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profile > Comment templates > User deletes comment template', :js,
  feature_category: :user_profile do
  let_it_be(:user) { create(:user) }
  let_it_be(:saved_reply) { create(:saved_reply, user: user) }

  before do
    sign_in(user)
  end

  it 'shows the user a list of their comment template' do
    visit profile_comment_templates_path

    click_button 'Comment template actions'
    find_by_testid('comment-template-delete-btn').click

    page.within('.gl-modal') do
      click_button 'Delete'
    end

    wait_for_requests

    expect(page).not_to have_content(saved_reply.name)
  end
end
