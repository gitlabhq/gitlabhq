# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profile > Comment templates > User creates comment template', :js,
  feature_category: :user_profile do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)

    visit profile_comment_templates_path

    wait_for_requests
  end

  it 'shows the user a list of their saved replies' do
    click_button 'Add new'
    find_by_testid('comment-template-name-input').set('test')
    find_by_testid('comment-template-content-input').set('Test content')

    click_button 'Save'

    wait_for_requests

    expect(page).to have_content('Comment templates')
    expect(page).to have_content('test')
    expect(page).to have_content('Test content')
  end
end
