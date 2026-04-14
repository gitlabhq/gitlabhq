# frozen_string_literal: true

class QueueBackfillOwasp2017FromIdentifiers < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  MIGRATION = "BackfillOwasp2017FromIdentifiers"
  SUB_BATCH_SIZE = 500

  def up
    queue_batched_background_migration(
      MIGRATION,
      :vulnerability_reads,
      :id,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :vulnerability_reads, :id, [])
  end
end
