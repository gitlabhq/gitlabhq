# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin visits service templates' do
  let(:admin) { create(:user, :admin) }
  let(:slack_integration) { Integration.for_template.find { |s| s.type == 'SlackService' } }

  before do
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  context 'without an active service template' do
    before do
      visit(admin_application_settings_services_path)
    end

    it 'does not show service template content' do
      expect(page).not_to have_content('Service template allows you to set default values for integrations')
    end
  end

  context 'with an active service template' do
    before do
      create(:integrations_slack, :template, active: true)
      visit(admin_application_settings_services_path)
    end

    it 'shows service template content' do
      expect(page).to have_content('Service template allows you to set default values for integrations')
    end

    context 'without instance-level integration' do
      it 'shows a link to service template' do
        expect(page).to have_link('Slack', href: edit_admin_application_settings_service_path(slack_integration.id))
        expect(page).not_to have_link('Slack', href: edit_admin_application_settings_integration_path(slack_integration))
      end
    end

    context 'with instance-level integration' do
      before do
        create(:integrations_slack, instance: true, project: nil)
        visit(admin_application_settings_services_path)
      end

      it 'shows a link to instance-level integration' do
        expect(page).not_to have_link('Slack', href: edit_admin_application_settings_service_path(slack_integration.id))
        expect(page).to have_link('Slack', href: edit_admin_application_settings_integration_path(slack_integration))
      end
    end
  end
end
