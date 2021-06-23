# frozen_string_literal: true

module Clusters
  module Applications
    class ActivateServiceWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker

      sidekiq_options retry: 3
      include ClusterQueue

      loggable_arguments 1

      def perform(cluster_id, service_name)
        cluster = Clusters::Cluster.find_by_id(cluster_id)
        return unless cluster

        cluster.all_projects.find_each do |project|
          project.find_or_initialize_integration(service_name).update!(active: true)
        end
      end
    end
  end
end
