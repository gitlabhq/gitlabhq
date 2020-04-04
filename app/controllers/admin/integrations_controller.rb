# frozen_string_literal: true

class Admin::IntegrationsController < Admin::ApplicationController
  include IntegrationsActions

  private

  def find_or_initialize_integration(name)
    if name.in?(Service.available_services_names)
      "#{name}_service".camelize.constantize.find_or_initialize_by(instance: true) # rubocop:disable CodeReuse/ActiveRecord
    end
  end

  def integrations_enabled?
    Feature.enabled?(:instance_level_integrations)
  end

  def scoped_edit_integration_path(integration)
    edit_admin_application_settings_integration_path(integration)
  end
end
