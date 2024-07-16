# frozen_string_literal: true

class RemoveForeignKeyGeoEventLog < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  disable_ddl_transaction!

  FROM_TABLE = :geo_event_log
  TO_TABLE = :geo_repositories_changed_events

  def up
    with_lock_retries do
      remove_foreign_key(
        FROM_TABLE,
        TO_TABLE,
        column: :repositories_changed_event_id,
        if_exists: true
      )
    end
  end

  def down
    add_concurrent_foreign_key(
      FROM_TABLE,
      TO_TABLE,
      name: :fk_4a99ebfd60,
      column: :repositories_changed_event_id,
      on_delete: :cascade
    )
  end
end
