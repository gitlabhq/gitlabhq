# frozen_string_literal: true

class Admin::IntegrationsController < Admin::ApplicationController
  include IntegrationsActions

  private

  def integrations_enabled?
    Feature.enabled?(:instance_level_integrations)
  end

  def scoped_edit_integration_path(integration)
    edit_admin_application_settings_integration_path(integration)
  end
end
