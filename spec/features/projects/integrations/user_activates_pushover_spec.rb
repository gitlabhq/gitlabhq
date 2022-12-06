# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Pushover', feature_category: :integrations do
  include_context 'project integration activation'

  before do
    stub_request(:post, /.*api.pushover.net.*/)
  end

  it 'activates integration', :js do
    visit_project_integration('Pushover')
    fill_in('API key', with: 'verySecret')
    fill_in('User key', with: 'verySecret')
    fill_in('Device', with: 'myDevice')
    select('High priority', from: 'Priority')
    select('Bike', from: 'Sound')

    click_test_then_save_integration(expect_test_to_fail: false)

    expect(page).to have_content('Pushover settings saved and active.')
  end
end
