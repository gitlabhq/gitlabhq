# frozen_string_literal: true

module JiraConnect
  class SyncDeploymentsWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    sidekiq_options retry: 3

    queue_namespace :jira_connect
    feature_category :integrations
    data_consistency :delayed, feature_flag: :load_balancing_for_jira_connect_workers
    tags :exclude_from_kubernetes

    worker_has_external_dependencies!

    def perform(deployment_id, sequence_id)
      deployment = Deployment.find_by_id(deployment_id)

      return unless deployment

      ::JiraConnect::SyncService
        .new(deployment.project)
        .execute(deployments: [deployment], update_sequence_id: sequence_id)
    end

    def self.perform_async(id)
      seq_id = ::Atlassian::JiraConnect::Client.generate_update_sequence_id
      super(id, seq_id)
    end
  end
end
