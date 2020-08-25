# frozen_string_literal: true

class Admin::IntegrationsController < Admin::ApplicationController
  include IntegrationsActions

  private

  def find_or_initialize_integration(name)
    Service.find_or_initialize_integration(name, instance: true)
  end

  def integrations_enabled?
    true
  end

  def scoped_edit_integration_path(integration)
    edit_admin_application_settings_integration_path(integration)
  end
end
