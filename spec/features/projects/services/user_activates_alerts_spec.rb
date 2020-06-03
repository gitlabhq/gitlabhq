# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Alerts', :js do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:service_name) { 'alerts' }
  let(:service_title) { 'Alerts endpoint' }

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  context 'when service is deactivated' do
    it 'activates service' do
      visit_project_services

      expect(page).to have_link(service_title)
      click_link(service_title)

      expect(page).not_to have_active_service

      click_activate_service
      wait_for_requests

      expect(page).to have_active_service
    end
  end

  context 'when service is activated' do
    before do
      visit_alerts_service
      click_activate_service
    end

    it 're-generates key' do
      expect(reset_key.value).to be_blank

      click_reset_key
      click_confirm_reset_key
      wait_for_requests

      expect(reset_key.value).to be_present
    end
  end

  private

  def visit_project_services
    visit(project_settings_integrations_path(project))
  end

  def visit_alerts_service
    visit(edit_project_service_path(project, service_name))
  end

  def click_activate_service
    find('#activated').click
  end

  def click_reset_key
    click_button('Reset key')
  end

  def click_confirm_reset_key
    within '.modal-content' do
      click_reset_key
    end
  end

  def reset_key
    find_field('Authorization key')
  end

  def have_active_service
    have_selector('.js-service-active-status[data-value="true"]')
  end
end
