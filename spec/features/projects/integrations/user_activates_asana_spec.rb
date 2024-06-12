# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Asana', feature_category: :integrations do
  include_context 'project integration activation'

  before do
    stub_request(:get, Integrations::Asana::PERSONAL_ACCESS_TOKEN_TEST_URL)
  end

  it 'activates integration', :js do
    visit_project_integration('Asana')
    fill_in('API key', with: 'verySecret')
    fill_in('Restrict to branch', with: 'verySecret')

    click_test_then_save_integration(expect_test_to_fail: false)

    expect(page).to have_content('Asana settings saved and active.')
  end
end
