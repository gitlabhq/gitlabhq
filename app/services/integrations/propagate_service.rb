# frozen_string_literal: true

module Integrations
  class PropagateService
    BATCH_SIZE = 10_000

    def initialize(integration)
      @integration = integration
    end

    def execute
      return propagate_instance_level_integration if integration.instance_level?

      if integration.class.instance_specific?
        update_descendant_integrations
      else
        update_inherited_descendant_integrations
      end

      propagate_integration_to_descendant_groups
      propagate_integration_to_descendant_projects
    end

    private

    attr_reader :integration

    def propagate_instance_level_integration
      update_inherited_integrations
      create_integration_for_groups_without_integration
      create_integration_for_projects_without_integration
    end

    def create_integration_for_projects_without_integration
      propagate_integrations(
        Project.without_integration(integration),
        PropagateIntegrationProjectWorker
      )
    end

    def update_inherited_integrations
      propagate_integrations(
        Integration.by_type(integration.type).inherit_from_id(integration.id),
        PropagateIntegrationInheritWorker
      )
    end

    def update_descendant_integrations
      propagate_integrations(
        Integration.descendants_from_self_or_ancestors_from(integration),
        PropagateIntegrationDescendantWorker
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

    def propagate_integration_to_descendant_groups
      if Feature.enabled?(:integration_propagation_simplified_batching, integration.group.root_ancestor)
        # Skip without_integration filter here - the worker re-applies it.
        # Keeping the batch scope simple avoids expensive OFFSET queries.
        # See https://gitlab.com/gitlab-org/gitlab/-/issues/591182
        propagate_integrations(
          integration.group.descendants,
          PropagateIntegrationGroupWorker
        )
      else
        propagate_integrations(
          integration.group.descendants.without_integration(integration),
          PropagateIntegrationGroupWorker
        )
      end
    end

    def propagate_integration_to_descendant_projects
      if Feature.enabled?(:integration_propagation_simplified_batching, integration.group.root_ancestor)
        # Pluck namespace IDs first, then batch on a simple IN (ids) scope.
        # The worker re-applies all filters, so we skip them here to
        # avoid expensive OFFSET queries in each_batch.
        # See https://gitlab.com/gitlab-org/gitlab/-/issues/591182
        namespace_ids = integration.group
          .self_and_descendants
          .excluding_self_and_ancestors_archived
          .ids # rubocop:disable CodeReuse/ActiveRecord -- avoids subquery in each_batch scope

        return if namespace_ids.empty?

        propagate_integrations(
          Project.in_namespace(namespace_ids),
          PropagateIntegrationProjectWorker
        )
      else
        propagate_integrations(
          Project.without_integration_excluding_ancestor_archived_check(integration)
                .in_namespace(integration.group.self_and_descendants.excluding_self_and_ancestors_archived),
          PropagateIntegrationProjectWorker
        )
      end
    end

    def propagate_integrations(relation, worker_class)
      relation.each_batch(of: BATCH_SIZE) do |records|
        min_id, max_id = records.pick("MIN(#{relation.table_name}.id), MAX(#{relation.table_name}.id)")
        worker_class.perform_async(integration.id, min_id, max_id)
      end
    end
  end
end
