# frozen_string_literal: true

class RemoveForeignKeysGeoEventLog < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.0'

  FROM_TABLE = :geo_event_log

  FOREIGN_KEYS = [
    {
      to_table: :geo_hashed_storage_migrated_events,
      options: {
        name: :fk_27548c6db3,
        column: [:hashed_storage_migrated_event_id],
        on_delete: :cascade
      }
    },
    {
      to_table: :geo_repository_updated_events,
      options: {
        name: :fk_rails_78a6492f68,
        column: [:repository_updated_event_id],
        on_delete: :cascade
      }
    },
    {
      to_table: :geo_repository_renamed_events,
      options: {
        name: :fk_86c84214ec,
        column: [:repository_renamed_event_id],
        on_delete: :cascade
      }
    },
    {
      to_table: :geo_repository_created_events,
      options: {
        name: :fk_9b9afb1916,
        column: [:repository_created_event_id],
        on_delete: :cascade
      }
    },
    {
      to_table: :geo_repository_deleted_events,
      options: {
        name: :fk_c4b1c1f66e,
        column: [:repository_deleted_event_id],
        on_delete: :cascade
      }
    },
    {
      to_table: :geo_reset_checksum_events,
      options: {
        name: :fk_cff7185ad2,
        column: [:reset_checksum_event_id],
        on_delete: :cascade
      }
    }
  ]

  def up
    FOREIGN_KEYS.each do |fk|
      with_lock_retries do
        remove_foreign_key(
          FROM_TABLE,
          fk[:to_table],
          column: fk[:options][:column].first.to_s,
          if_exists: true
        )
      end
    end
  end

  def down
    FOREIGN_KEYS.each do |fk|
      add_concurrent_foreign_key(FROM_TABLE, fk[:to_table], **fk[:options])
    end
  end
end
