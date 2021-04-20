# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Pushover' do
  include_context 'project service activation'

  before do
    stub_request(:post, /.*api.pushover.net.*/)
  end

  it 'activates service', :js do
    visit_project_integration('Pushover')
    fill_in('API key', with: 'verySecret')
    fill_in('User key', with: 'verySecret')
    fill_in('Device', with: 'myDevice')
    select('High Priority', from: 'Priority')
    select('Bike', from: 'Sound')

    click_test_then_save_integration(expect_test_to_fail: false)

    expect(page).to have_content('Pushover settings saved and active.')
  end
end
