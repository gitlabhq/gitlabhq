# frozen_string_literal: true

module Clusters
  module Applications
    class DeactivateIntegrationWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3
      include ClusterQueue

      loggable_arguments 1

      def perform(cluster_id, integration_name); end
    end
  end
end
