# frozen_string_literal: true

class ReplaceUniqueIndexOnCdVersionSetEntries < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  OLD_INDEX_NAME = 'index_cd_version_set_entries_on_version_set_id_and_service_id'
  NEW_INDEX_NAME = 'index_cd_vs_entries_on_version_set_id_and_artifact_source_id'

  def up
    add_concurrent_index :cd_version_set_entries, [:version_set_id, :artifact_source_id],
      unique: true, name: NEW_INDEX_NAME

    remove_concurrent_index_by_name :cd_version_set_entries, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :cd_version_set_entries, [:version_set_id, :service_id],
      unique: true, name: OLD_INDEX_NAME

    remove_concurrent_index_by_name :cd_version_set_entries, NEW_INDEX_NAME
  end
end
