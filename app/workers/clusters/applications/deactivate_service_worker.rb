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

        integration_class = Integration.integration_name_to_model(integration_name)
        integration_association_name = ::Project.integration_association_name(integration_name).to_sym

        cluster.all_projects.with_integration(integration_class).include_integration(integration_association_name).find_each do |project|
          project.public_send(integration_association_name).update!(active: false) # rubocop:disable GitlabSecurity/PublicSend
        end
      end

      def cluster_missing_error(integration_name)
        ActiveRecord::RecordNotFound.new("Can't deactivate #{integration_name} integrations, host cluster not found! Some inconsistent records may be left in database.")
      end
    end
  end
end
