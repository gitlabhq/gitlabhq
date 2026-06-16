# frozen_string_literal: true

class DropUploadsArchivedTable < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  milestone '19.1'

  disable_ddl_transaction!

  TABLE_NAME = 'uploads'
  ARCHIVED_TABLE_NAME = :uploads_archived
  LINGERING_INBOUND_FK_TABLE = :project_upload_states
  LINGERING_INBOUND_FK_NAME = :fk_a21cb2b8a2

  def up
    # Defensive cleanup: the replacement migration 20260424155934 was
    # supposed to drop this FK but silently no-op'd on some environments,
    # leaving it pointing at uploads_archived. Locally this is a no-op.
    with_lock_retries do
      remove_foreign_key_if_exists LINGERING_INBOUND_FK_TABLE,
        name: LINGERING_INBOUND_FK_NAME, reverse_lock_order: true
    end

    drop_nonpartitioned_archive_table(TABLE_NAME)
  end

  # rubocop:disable Migration/Datetime -- Matches the original timestamp-without-timezone column
  def down
    create_table ARCHIVED_TABLE_NAME, id: false do |t|
      t.bigint :id, null: false
      t.bigint :size, null: false
      t.string :path, limit: 511, null: false
      t.string :checksum, limit: 64
      t.bigint :model_id
      t.string :model_type
      t.string :uploader, null: false
      t.datetime :created_at, null: false
      t.integer :store, default: 1
      t.string :mount_point
      t.string :secret
      t.integer :version, default: 1, null: false
      t.bigint :uploaded_by_user_id
      t.bigint :organization_id
      t.bigint :namespace_id
      t.bigint :project_id

      t.check_constraint '(store IS NOT NULL)', name: 'check_5e9547379c'

      t.index :checksum, name: 'index_uploads_on_checksum'
      t.index [:model_id, :model_type, :uploader, :created_at],
        name: 'index_uploads_on_model_id_model_type_uploader_created_at'
      t.index :store, name: 'index_uploads_on_store'
      t.index :uploaded_by_user_id, name: 'index_uploads_on_uploaded_by_user_id'
      t.index [:uploader, :path], name: 'index_uploads_on_uploader_and_path'
    end

    execute "ALTER TABLE #{ARCHIVED_TABLE_NAME} ADD PRIMARY KEY (id)"

    create_trigger_to_sync_tables(TABLE_NAME, ARCHIVED_TABLE_NAME.to_s, 'id')
  end
  # rubocop:enable Migration/Datetime
end
