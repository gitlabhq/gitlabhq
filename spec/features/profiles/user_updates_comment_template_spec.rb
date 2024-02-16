# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profile > Comment templates > User updated comment template', :js,
  feature_category: :user_profile do
  let_it_be(:user) { create(:user) }
  let_it_be(:saved_reply) { create(:saved_reply, user: user) }

  before do
    sign_in(user)

    visit profile_comment_templates_path

    wait_for_requests
  end

  it 'shows the user a list of their comment template' do
    click_button 'Comment template actions'

    find_by_testid('comment-template-edit-btn').click
    find_by_testid('comment-template-name-input').set('test')

    click_button 'Save'

    wait_for_requests

    expect(page).to have_selector('[data-testid="comment-template-name"]', text: 'test')
  end
end
