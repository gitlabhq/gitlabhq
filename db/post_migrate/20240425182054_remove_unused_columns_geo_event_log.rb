# frozen_string_literal: true

class RemoveUnusedColumnsGeoEventLog < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.0'

  TABLE_NAME = :geo_event_log

  UNUSED_COLUMNS = %i[
    hashed_storage_attachments_event_id
    hashed_storage_migrated_event_id
    repository_created_event_id
    repository_updated_event_id
    repository_deleted_event_id
    repository_renamed_event_id
    reset_checksum_event_id
  ]

  def up
    UNUSED_COLUMNS.each do |column_name|
      remove_column(TABLE_NAME, column_name, if_exists: true)
    end
  end

  def down
    UNUSED_COLUMNS.each do |column_name|
      add_column(TABLE_NAME, column_name, :bigint, if_not_exists: true)

      add_concurrent_index(
        TABLE_NAME,
        column_name,
        name: "index_#{TABLE_NAME}_on_#{column_name}",
        where: "#{column_name} IS NOT NULL")
    end
  end
end
