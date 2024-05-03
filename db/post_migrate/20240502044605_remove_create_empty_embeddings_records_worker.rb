# frozen_string_literal: true

class RemoveCreateEmptyEmbeddingsRecordsWorker < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  disable_ddl_transaction!

  def up
    # This is to clean up the cron schedule for Llm::Embedding::GitlabDocumentation::CreateEmptyEmbeddingsRecordsWorker
    # which was removed in
    # https://gitlab.com/gitlab-org/gitlab/-/issues/438337
    # TODO: make shard-aware. See https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/3430
    Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
      removed_job = Sidekiq::Cron::Job.find('llm_embedding_gitlab_documentation_create_empty_embeddings_records_worker')
      removed_job.destroy if removed_job
    end
  end

  def down
    # This is to remove the cron schedule for a deleted job, so there is no
    # meaningful way to reverse it.
  end
end
