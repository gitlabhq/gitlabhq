# frozen_string_literal: true

module Clusters
  module Applications
    class DeactivateServiceWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3
      include ClusterQueue

      loggable_arguments 1

      def perform(cluster_id, integration_name)
        cluster = Clusters::Cluster.find_by_id(cluster_id)
        raise cluster_missing_error(integration_name) unless cluster

        integration = ::Project.integration_association_name(integration_name).to_sym
        cluster.all_projects.with_integration(integration).find_each do |project|
          project.public_send(integration).update!(active: false) # rubocop:disable GitlabSecurity/PublicSend
        end
      end

      def cluster_missing_error(integration_name)
        ActiveRecord::RecordNotFound.new("Can't deactivate #{integration_name} integrations, host cluster not found! Some inconsistent records may be left in database.")
      end
    end
  end
end
