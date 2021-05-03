# frozen_string_literal: true

module JiraConnect
  class SyncFeatureFlagsWorker
    include ApplicationWorker

    sidekiq_options retry: 3

    idempotent!
    worker_has_external_dependencies!

    queue_namespace :jira_connect
    feature_category :integrations
    tags :exclude_from_kubernetes

    def perform(feature_flag_id, sequence_id)
      feature_flag = ::Operations::FeatureFlag.find_by_id(feature_flag_id)

      return unless feature_flag

      ::JiraConnect::SyncService
        .new(feature_flag.project)
        .execute(feature_flags: [feature_flag], update_sequence_id: sequence_id)
    end
  end
end
