# frozen_string_literal: true

require 'spec_helper'

describe 'Prometheus external alerts', :js do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  let(:alerts_section_selector) { '.js-prometheus-alerts' }
  let(:alerts_section) { page.find(alerts_section_selector) }

  before do
    sign_in(user)
    project.add_maintainer(user)

    visit_edit_service
  end

  context 'with manual configuration' do
    before do
      create(:prometheus_service, project: project, api_url: 'http://prometheus.example.com', manual_configuration: '1', active: true)
    end

    it 'shows the Alerts section' do
      visit_edit_service

      expect(alerts_section).to have_content('Alerts')
      expect(alerts_section).to have_content('Receive alerts from manually configured Prometheus servers.')
      expect(alerts_section).to have_content('URL')
      expect(alerts_section).to have_content('Authorization key')
    end
  end

  context 'with no configuration' do
    it 'does not show the Alerts section' do
      wait_for_requests

      expect(page).not_to have_css(alerts_section_selector)
    end
  end

  private

  def visit_edit_service
    visit(project_settings_integrations_path(project))
    click_link('Prometheus')
  end
end
