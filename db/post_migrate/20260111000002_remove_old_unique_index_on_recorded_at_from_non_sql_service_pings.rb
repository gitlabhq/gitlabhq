# frozen_string_literal: true

class RemoveOldUniqueIndexOnRecordedAtFromNonSqlServicePings < Gitlab::Database::Migration[2.3]
  milestone '18.9'
  disable_ddl_transaction!

  TABLE_NAME = :non_sql_service_pings
  OLD_INDEX_NAME = 'index_non_sql_service_pings_on_recorded_at'
  ORG_INDEX_NAME = 'index_non_sql_service_pings_on_organization_id'

  def up
    remove_concurrent_index_by_name TABLE_NAME, OLD_INDEX_NAME
    remove_concurrent_index_by_name TABLE_NAME, ORG_INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, :recorded_at, unique: true, name: OLD_INDEX_NAME
    add_concurrent_index TABLE_NAME, :organization_id, name: ORG_INDEX_NAME
  end
end
