# frozen_string_literal: true

class UnscheduleOpenAiClearConvosCron < Gitlab::Database::Migration[2.2]
  milestone '16.10'
  disable_ddl_transaction!

  def up
    # This is to clean up the cron schedule for OpenAi::ClearConversationsWorker
    # which was removed in
    # https://gitlab.com/gitlab-org/gitlab/-/commit/8c24e145c14d64c62a5b4f6fe72726140457d9f1#be4e3233708096a83c31a905040cb84cc105703d_780_780
    # TODO: make shard-aware. See https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/3430
    Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
      Sidekiq::Cron::Job.destroy('open_ai_clear_conversations')
    end

    sidekiq_remove_jobs(job_klasses: %w[OpenAi::ClearConversationsWorker])
  end

  def down
    # No-op
  end
end
