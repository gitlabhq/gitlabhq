# frozen_string_literal: true

class AddUniqueIndexOnOrganizationIdRecordedAtToQueriesServicePings < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  disable_ddl_transaction!

  TABLE_NAME = :queries_service_pings
  NEW_INDEX_NAME = 'index_queries_service_pings_on_org_id_recorded_at'

  def up
    add_concurrent_index TABLE_NAME, [:organization_id, :recorded_at], unique: true, name: NEW_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, NEW_INDEX_NAME
  end
end
