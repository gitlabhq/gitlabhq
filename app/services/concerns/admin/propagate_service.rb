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
      Project.without_integration(integration).each_batch(of: BATCH_SIZE) do |projects|
        min_id, max_id = projects.pick("MIN(projects.id), MAX(projects.id)")
        PropagateIntegrationProjectWorker.perform_async(integration.id, min_id, max_id)
      end
    end
  end
end
