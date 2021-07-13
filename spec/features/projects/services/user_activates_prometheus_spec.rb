# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Prometheus' do
  include_context 'project service activation'

  before do
    stub_request(:get, /.*prometheus.example.com.*/)
  end

  it 'does not activate service and informs about deprecation', :js do
    visit_project_integration('Prometheus')
    check('Active')
    fill_in('API URL', with: 'http://prometheus.example.com')

    click_button('Save changes')

    expect(page).not_to have_content('Prometheus settings saved and active.')
    expect(page).to have_content('Fields on this page have been deprecated.')
  end
end
