# frozen_string_literal: true

class Admin::IntegrationsController < Admin::ApplicationController
  include IntegrationsActions
  include IntegrationsHelper

  before_action :not_found, unless: -> { instance_level_integrations? }

  feature_category :integrations

  private

  def find_or_initialize_non_project_specific_integration(name)
    Integration.find_or_initialize_non_project_specific_integration(name, instance: true)
  end

  def scoped_edit_integration_path(integration)
    edit_admin_application_settings_integration_path(integration)
  end
end
