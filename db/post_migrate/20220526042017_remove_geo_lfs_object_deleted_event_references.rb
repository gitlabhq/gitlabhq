# frozen_string_literal: true

class RemoveGeoLfsObjectDeletedEventReferences < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_column :geo_event_log, :lfs_object_deleted_event_id, :bigint
    end
  end

  def down
    with_lock_retries do
      unless column_exists?(:geo_event_log, :lfs_object_deleted_event_id)
        add_column(:geo_event_log, :lfs_object_deleted_event_id, :bigint)
      end
    end

    add_concurrent_foreign_key :geo_event_log, :geo_lfs_object_deleted_events,
                               column: :lfs_object_deleted_event_id,
                               name: 'fk_d5af95fcd9',
                               on_delete: :cascade

    add_concurrent_index :geo_event_log,
                         :lfs_object_deleted_event_id,
                         name: 'index_geo_event_log_on_lfs_object_deleted_event_id',
                         where: "(lfs_object_deleted_event_id IS NOT NULL)"
  end
end
