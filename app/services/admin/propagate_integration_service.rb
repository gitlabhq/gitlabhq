# frozen_string_literal: true

module Admin
  class PropagateIntegrationService
    include PropagateService

    def propagate
      if integration.instance_level?
        update_inherited_integrations
        create_integration_for_groups_without_integration
        create_integration_for_projects_without_integration
      else
        update_inherited_descendant_integrations
        create_integration_for_groups_without_integration_belonging_to_group
        create_integration_for_projects_without_integration_belonging_to_group
      end
    end

    private

    def update_inherited_integrations
      propagate_integrations(
        Integration.by_type(integration.type).inherit_from_id(integration.id),
        PropagateIntegrationInheritWorker
      )
    end

    def update_inherited_descendant_integrations
      propagate_integrations(
        Integration.inherited_descendants_from_self_or_ancestors_from(integration),
        PropagateIntegrationInheritDescendantWorker
      )
    end

    def create_integration_for_groups_without_integration
      propagate_integrations(
        Group.without_integration(integration),
        PropagateIntegrationGroupWorker
      )
    end

    def create_integration_for_groups_without_integration_belonging_to_group
      propagate_integrations(
        integration.group.descendants.without_integration(integration),
        PropagateIntegrationGroupWorker
      )
    end

    def create_integration_for_projects_without_integration_belonging_to_group
      propagate_integrations(
        Project.without_integration(integration).in_namespace(integration.group.self_and_descendants),
        PropagateIntegrationProjectWorker
      )
    end
  end
end
