# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Prometheus external alerts', :js do
  include_context 'project service activation'

  let(:alerts_section_selector) { '.js-prometheus-alerts' }
  let(:alerts_section) { page.find(alerts_section_selector) }

  context 'with manual configuration' do
    before do
      create(:prometheus_integration, project: project, api_url: 'http://prometheus.example.com', manual_configuration: '1', active: true)
    end

    it 'shows the Alerts section' do
      visit_project_integration('Prometheus')

      expect(alerts_section).to have_content('Alerts')
      expect(alerts_section).to have_content('Receive alerts from manually configured Prometheus servers.')
      expect(alerts_section).to have_content('URL')
      expect(alerts_section).to have_content('Authorization key')
    end
  end

  context 'with no configuration' do
    it 'does not show the Alerts section' do
      visit_project_integration('Prometheus')
      wait_for_requests

      expect(page).not_to have_css(alerts_section_selector)
    end
  end
end
