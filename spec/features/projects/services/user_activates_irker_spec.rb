# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Irker (IRC gateway)' do
  include_context 'project service activation'

  it 'activates service', :js do
    visit_project_integration('Irker (IRC gateway)')
    check('Colorize messages')
    fill_in('Recipients', with: 'irc://chat.freenode.net/#commits')

    click_test_integration

    expect(page).to have_content('Irker (IRC gateway) activated.')
  end
end
