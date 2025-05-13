# frozen_string_literal: true

module Environments
  class DeleteManagedResourcesService
    include Gitlab::Utils::StrongMemoize

    def initialize(environment, current_user:)
      @environment = environment
      @current_user = current_user
    end

    def execute
      return unless can_delete_resources?

      managed_resource.update!(status: :deleting)

      Clusters::Agents::ManagedResources::DeleteWorker.perform_async(managed_resource.id)

      emit_event

      ServiceResponse.success
    end

    private

    attr_reader :environment, :current_user

    def can_delete_resources?
      environment.stopped? &&
        managed_resource.present? &&
        managed_resource.cluster_agent.resource_management_enabled? &&
        managed_resource.deletion_strategy_on_stop?
    end

    def managed_resource
      environment.managed_resources.completed.order_id_desc.first
    end
    strong_memoize_attr :managed_resource

    def emit_event
      Gitlab::InternalEvents.track_event(
        'delete_environment_for_managed_resource',
        user: current_user,
        project: environment.project,
        additional_properties: {
          label: environment.project.namespace.actual_plan_name,
          property: environment.tier,
          value: environment.id
        }
      )
    end
  end
end
