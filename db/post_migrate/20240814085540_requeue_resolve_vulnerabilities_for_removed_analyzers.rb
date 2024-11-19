# frozen_string_literal: true

class RequeueResolveVulnerabilitiesForRemovedAnalyzers < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "ResolveVulnerabilitiesForRemovedAnalyzers"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 100

  def up
    Gitlab::Database::QueryAnalyzers::Base.suppress_schema_issues_for_decomposed_tables do
      # Clear previous background migration execution from QueueResolveVulnerabilitiesForRemovedAnalyzers
      delete_batched_background_migration(MIGRATION, :vulnerability_reads, :id, [])

      queue_batched_background_migration(
        MIGRATION,
        :vulnerability_reads,
        :id,
        job_interval: DELAY_INTERVAL,
        batch_size: BATCH_SIZE,
        sub_batch_size: SUB_BATCH_SIZE
      )
    end
  end

  def down
    Gitlab::Database::QueryAnalyzers::Base.suppress_schema_issues_for_decomposed_tables do
      delete_batched_background_migration(MIGRATION, :vulnerability_reads, :id, [])
    end
  end
end
