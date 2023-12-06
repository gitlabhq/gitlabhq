# frozen_string_literal: true

class AddCatalogResourceSyncEventsTable < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  enable_lock_retries!

  def up
    options = {
      primary_key: [:id, :partition_id],
      options: 'PARTITION BY LIST (partition_id)',
      if_not_exists: true
    }

    create_table(:p_catalog_resource_sync_events, **options) do |t|
      t.bigserial :id, null: false
      # We will not bother with foreign keys as they come with a performance cost; they will get cleaned up over time.
      t.bigint :catalog_resource_id, null: false
      t.bigint :project_id, null: false
      t.bigint :partition_id, null: false, default: 1
      t.integer :status, null: false, default: 1, limit: 2
      t.timestamps_with_timezone null: false, default: -> { 'NOW()' }

      t.index :id,
        where: 'status = 1',
        name: :index_p_catalog_resource_sync_events_on_id_where_pending
    end

    connection.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.p_catalog_resource_sync_events_1
        PARTITION OF p_catalog_resource_sync_events
        FOR VALUES IN (1);
    SQL
  end

  def down
    drop_table :p_catalog_resource_sync_events
  end
end
