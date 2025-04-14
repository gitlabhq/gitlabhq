# frozen_string_literal: true

class MigrateOldDisabledWebHookToNewState < Gitlab::Database::Migration[2.2]
  BATCH_SIZE = 1000
  TABLE = 'web_hooks'
  SCOPE = ->(table) {
    table.where('recent_failures > 3').where(disabled_until: nil)
  }.freeze

  NEW_RECENT_FAILURES = 40 # WebHooks::AutoDisabling::PERMANENTLY_DISABLED_FAILURE_THRESHOLD + 1
  NEW_BACKOFF_COUNT = 37 # NEW_RECENT_FAILURES - WebHooks::AutoDisabling::FAILURE_THRESHOLD

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.11'

  def up
    disabled_until = Time.zone.now.to_fs(:db) # Specific time does not matter, just needs to be present

    each_batch(TABLE, connection: connection, scope: SCOPE, of: BATCH_SIZE) do |batch, _batchable_model|
      batch.update_all(
        recent_failures: NEW_RECENT_FAILURES,
        backoff_count: NEW_BACKOFF_COUNT,
        disabled_until: disabled_until
      )
    end
  end

  def down
    # no-op
  end
end
