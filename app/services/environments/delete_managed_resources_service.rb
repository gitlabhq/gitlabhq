# frozen_string_literal: true

module Environments
  class DeleteManagedResourcesService
    include Gitlab::Utils::StrongMemoize

    def initialize(environment)
      @environment = environment
    end

    def execute
      return unless can_delete_resources?

      managed_resource.update!(status: :deleting)

      Clusters::Agents::ManagedResources::DeleteWorker.perform_async(managed_resource.id)

      ServiceResponse.success
    end

    private

    attr_reader :environment

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
  end
end
