# frozen_string_literal: true

class Admin::IntegrationsController < Admin::ApplicationController
  include IntegrationsActions
  include ServicesHelper

  feature_category :integrations

  private

  def find_or_initialize_non_project_specific_integration(name)
    Service.find_or_initialize_non_project_specific_integration(name, instance: true)
  end

  def integrations_enabled?
    instance_level_integrations?
  end

  def scoped_edit_integration_path(integration)
    edit_admin_application_settings_integration_path(integration)
  end
end
