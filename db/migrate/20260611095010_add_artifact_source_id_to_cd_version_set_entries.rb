# frozen_string_literal: true

class AddArtifactSourceIdToCdVersionSetEntries < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  def up
    add_column :cd_version_set_entries, :artifact_source_id, :bigint, if_not_exists: true

    add_concurrent_index :cd_version_set_entries, :artifact_source_id
    add_not_null_constraint :cd_version_set_entries, :artifact_source_id
  end

  def down
    remove_not_null_constraint :cd_version_set_entries, :artifact_source_id
    remove_column :cd_version_set_entries, :artifact_source_id, if_exists: true
  end
end
