# frozen_string_literal: true

class RemoveContainerRepositoryDeprecatedGeoFields < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_column :geo_event_log, :container_repository_updated_event_id, :bigint
    end
  end

  def down
    with_lock_retries do
      unless column_exists?(:geo_event_log, :container_repository_updated_event_id)
        add_column(:geo_event_log, :container_repository_updated_event_id, :bigint)
      end
    end

    add_concurrent_foreign_key :geo_event_log, :geo_container_repository_updated_events,
                               column: :container_repository_updated_event_id,
                               name: 'fk_6ada82d42a',
                               on_delete: :cascade

    add_concurrent_index :geo_event_log,
                         :container_repository_updated_event_id,
                         name: 'index_geo_event_log_on_container_repository_updated_event_id'
  end
end
