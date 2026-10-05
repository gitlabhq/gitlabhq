# frozen_string_literal: true

class Admin::IntegrationsController < Admin::ApplicationController
  include ::Integrations::Actions

  before_action :not_found, unless: -> { instance_level_integrations? }
  before_action only: [:edit] do
    push_frontend_feature_flag(:finer_filters_for_integrations)
  end

  feature_category :integrations

  def overrides
    respond_to do |format|
      format.json do
        projects = Project.in_organization(admin_current_organization)
                          .with_active_integration(integration.class)
                          .merge(::Integration.overriding_instance_default(integration))
        serializer = ::Integrations::ProjectSerializer.new.with_pagination(request, response)

        render json: serializer.represent(projects)
      end
      format.html { render 'shared/integrations/overrides' }
    end
  end

  private

  def find_or_initialize_non_project_specific_integration(name)
    Integration.find_or_initialize_non_project_specific_integration(
      name,
      instance: true,
      organization_id: admin_current_organization.id
    )
  end
end
