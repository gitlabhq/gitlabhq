# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin visits service templates' do
  let(:admin) { create(:user, :admin) }
  let(:slack_service) { Service.for_template.find { |s| s.type == 'SlackService' } }

  before do
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)

    visit(admin_application_settings_services_path)
  end

  context 'without instance-level integration' do
    it 'shows a link to service template' do
      expect(page).to have_link('Slack', href: edit_admin_application_settings_service_path(slack_service.id))
      expect(page).not_to have_link('Slack', href: edit_admin_application_settings_integration_path(slack_service))
    end
  end

  context 'with instance-level integration' do
    let_it_be(:slack_instance_integration) { create(:slack_service, instance: true, project: nil) }

    it 'shows a link to instance-level integration' do
      expect(page).not_to have_link('Slack', href: edit_admin_application_settings_service_path(slack_service.id))
      expect(page).to have_link('Slack', href: edit_admin_application_settings_integration_path(slack_service))
    end
  end
end
