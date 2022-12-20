# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates irker (IRC gateway)', feature_category: :integrations do
  include_context 'project integration activation'

  it 'activates integration', :js do
    visit_project_integration('irker (IRC gateway)')
    check('Colorize messages')
    fill_in('Recipients', with: 'irc://chat.freenode.net/#commits')

    click_test_then_save_integration(expect_test_to_fail: false)

    expect(page).to have_content('irker (IRC gateway) settings saved and active.')
  end
end
