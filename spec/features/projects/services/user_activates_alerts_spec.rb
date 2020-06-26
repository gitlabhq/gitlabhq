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
    it 'user cannot activate service' do
      visit_project_services

      expect(page).to have_link(service_title)
      click_link(service_title)

      expect(page).to have_callout_message
      expect(page).not_to have_active_service
      expect(page).to have_toggle_active_disabled
    end
  end

  context 'when service is activated' do
    let_it_be(:activated_alerts_service) do
      create(:alerts_service, :active, project: project)
    end

    before do
      visit_alerts_service
    end

    it 'user cannot change settings' do
      expect(page).to have_callout_message
      expect(page).to have_active_service
      expect(page).to have_toggle_active_disabled
      expect(page).to have_button_reset_key_disabled
    end
  end

  private

  def visit_project_services
    visit(project_settings_integrations_path(project))
  end

  def visit_alerts_service
    visit(edit_project_service_path(project, service_name))
  end

  def have_callout_message
    within('.gl-alert') do
      have_content('You can now manage alert endpoint configuration in the Alerts section on the Operations settings page.')
    end
  end

  def have_active_service
    have_selector('.js-service-active-status[data-value="true"]')
  end

  def have_toggle_active_disabled
    have_selector('#activated .project-feature-toggle.is-disabled')
  end

  def have_button_reset_key_disabled
    have_button('Reset key', disabled: true)
  end
end
