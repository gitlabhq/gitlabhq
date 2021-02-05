# frozen_string_literal: true

module JiraConnect
  class SyncBuildsWorker
    include ApplicationWorker

    idempotent!
    worker_has_external_dependencies!

    queue_namespace :jira_connect
    feature_category :integrations

    def perform(pipeline_id, sequence_id)
      pipeline = Ci::Pipeline.find_by_id(pipeline_id)

      return unless pipeline

      ::JiraConnect::SyncService
        .new(pipeline.project)
        .execute(pipelines: [pipeline], update_sequence_id: sequence_id)
    end
  end
end
