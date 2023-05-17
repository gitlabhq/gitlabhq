# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Prometheus', feature_category: :integrations do
  include_context 'project integration activation'

  before do
    stub_feature_flags(remove_monitor_metrics: false)
    stub_request(:get, /.*prometheus.example.com.*/)
  end

  it 'saves and activates integration', :js do
    visit_project_integration('Prometheus')
    check('Active')
    fill_in('API URL', with: 'http://prometheus.example.com')

    click_button('Save changes')

    expect(page).to have_content('Prometheus settings saved and active.')
  end
end
