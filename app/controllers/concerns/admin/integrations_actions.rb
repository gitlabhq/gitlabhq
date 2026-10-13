# frozen_string_literal: true

module Admin
  module IntegrationsActions
    extend ActiveSupport::Concern

    included do
      feature_category :integrations

      before_action only: [:edit] do
        push_frontend_feature_flag(:finer_filters_for_integrations)
      end
    end

    def overrides
      respond_to do |format|
        format.json do
          projects = Project.in_organization(integrations_organization)
                            .with_active_integration(integration.class)
                            .merge(::Integration.overriding_instance_default(integration))
          serializer = ::Integrations::ProjectSerializer.new.with_pagination(request, response)

          render json: serializer.represent(projects)
        end
        format.html { render 'shared/integrations/overrides' }
      end
    end

    private

    # The organization whose instance-level integrations are managed. Includers must override this.
    def integrations_organization
      raise NotImplementedError
    end

    def find_or_initialize_non_project_specific_integration(name)
      Integration.find_or_initialize_non_project_specific_integration(
        name,
        instance: true,
        organization_id: integrations_organization.id
      )
    end
  end
end
