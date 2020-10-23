# frozen_string_literal: true

module Admin
  module PropagateService
    extend ActiveSupport::Concern

    BATCH_SIZE = 10_000

    class_methods do
      def propagate(integration)
        new(integration).propagate
      end
    end

    def initialize(integration)
      @integration = integration
    end

    private

    attr_reader :integration

    def create_integration_for_projects_without_integration
      propagate_integrations(
        Project.without_integration(integration),
        PropagateIntegrationProjectWorker
      )
    end

    def propagate_integrations(relation, worker_class)
      relation.each_batch(of: BATCH_SIZE) do |records|
        min_id, max_id = records.pick("MIN(#{relation.table_name}.id), MAX(#{relation.table_name}.id)")
        worker_class.perform_async(integration.id, min_id, max_id)
      end
    end
  end
end
