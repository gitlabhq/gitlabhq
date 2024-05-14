# frozen_string_literal: true

class UnscheduleOpenAiClearConversationsWorker < Gitlab::Database::Migration[2.2]
  milestone '16.10'
  disable_ddl_transaction!

  def up
    # This is to clean up the cron schedule for OpenAi::ClearConversationsWorker
    # which was removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139626
    # TODO: make shard-aware. See https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/3430
    Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
      removed_job = Sidekiq::Cron::Job.find('open_ai_clear_conversations_worker')
      removed_job.destroy if removed_job
    end

    sidekiq_remove_jobs(job_klasses: %w[OpenAi::ClearConversationsWorker])
  end

  def down
    # No-op
  end
end
