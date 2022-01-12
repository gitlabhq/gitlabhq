# frozen_string_literal: true

class EncryptStaticObjectToken < Gitlab::Database::Migration[1.0]
  BATCH_SIZE = 10_000
  MIGRATION = 'EncryptStaticObjectToken'

  disable_ddl_transaction!

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      define_batchable_model('users').where.not(static_object_token: nil).where(static_object_token_encrypted: nil),
      MIGRATION,
      2.minutes,
      batch_size: BATCH_SIZE,
      track_jobs: true
    )
  end

  def down
    # no ops
  end
end
