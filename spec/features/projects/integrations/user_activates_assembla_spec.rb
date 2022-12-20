# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Assembla', feature_category: :integrations do
  include_context 'project integration activation'

  before do
    stub_request(:post, /.*atlas.assembla.com.*/)
  end

  it 'activates integration', :js do
    visit_project_integration('Assembla')
    fill_in('Token', with: 'verySecret')

    click_test_then_save_integration(expect_test_to_fail: false)

    expect(page).to have_content('Assembla settings saved and active.')
  end
end
