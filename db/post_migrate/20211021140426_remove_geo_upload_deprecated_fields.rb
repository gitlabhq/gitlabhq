# frozen_string_literal: true

class RemoveGeoUploadDeprecatedFields < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_column :geo_event_log, :upload_deleted_event_id, :bigint
    end
  end

  def down
    with_lock_retries do
      add_column(:geo_event_log, :upload_deleted_event_id, :bigint) unless column_exists?(:geo_event_log, :upload_deleted_event_id)
    end

    add_concurrent_foreign_key :geo_event_log, :geo_upload_deleted_events,
                               column: :upload_deleted_event_id,
                               name: 'fk_c1f241c70d',
                               on_delete: :cascade

    add_concurrent_index :geo_event_log,
                         :upload_deleted_event_id,
                         name: 'index_geo_event_log_on_upload_deleted_event_id',
                         where: "(upload_deleted_event_id IS NOT NULL)"
  end
end
