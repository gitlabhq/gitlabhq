# frozen_string_literal: true

class AddUniqueIndexOnCdVersionSetsEntriesDigest < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  INDEX_NAME = 'index_cd_version_sets_on_application_id_and_entries_digest'

  def up
    add_concurrent_index :cd_version_sets, [:application_id, :entries_digest],
      unique: true,
      where: 'entries_digest IS NOT NULL',
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :cd_version_sets, INDEX_NAME
  end
end
