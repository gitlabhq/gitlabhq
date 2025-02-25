# frozen_string_literal: true

class RemoveGeoEventLogRepositoriesChangedEventIdColumn < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.10'

  TABLE_NAME  = :geo_event_log
  COLUMN_NAME = :repositories_changed_event_id
  INDEX_NAME  = :index_geo_event_log_on_repositories_changed_event_id

  def up
    remove_column(TABLE_NAME, COLUMN_NAME)
  end

  def down
    add_column(TABLE_NAME, COLUMN_NAME, :bigint, if_not_exists: true)

    add_concurrent_index(TABLE_NAME, COLUMN_NAME, name: INDEX_NAME, where: 'repositories_changed_event_id IS NOT NULL')
  end
end
