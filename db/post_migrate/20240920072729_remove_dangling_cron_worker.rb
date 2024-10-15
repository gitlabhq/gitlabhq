# frozen_string_literal: true

class RemoveDanglingCronWorker < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.5'

  WORKER_CLASSES = [
    # Removed in https://gitlab.com/gitlab-org/gitlab/-/commit/84f8c88b8cebf5069eb4906b6170ea760e6b0a57
    'llm_embedding_gitlab_documentation_cleanup_previous_versions_records_worker',
    'llm_embedding_gitlab_documentation_create_embeddings_records_worker',
    # Removed in https://gitlab.com/gitlab-org/gitlab/-/commit/02b2519518037db8a8d0a71f1e57d2a9be1d3b39
    'vertex_ai_refresh_access_token_worker',
    # Removed in https://gitlab.com/gitlab-org/gitlab/-/commit/a2208c18bfd8351411740956fe33c482e1a0b68b
    'ci_platform_metrics_update_cron_worker',
    # Removed in https://gitlab.com/gitlab-org/gitlab/-/commit/011372de3f721c7903ea444f90e5a338f93d6aae
    'ensure_merge_requests_prepared_worker'
  ].freeze

  def up
    # TODO: make shard-aware. See https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/3430
    WORKER_CLASSES.each do |wc|
      Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
        Sidekiq::Cron::Job.destroy(wc)
      end
    end
  end

  def down; end
end
