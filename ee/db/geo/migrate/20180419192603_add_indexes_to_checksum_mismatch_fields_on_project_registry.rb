class AddIndexesToChecksumMismatchFieldsOnProjectRegistry < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  REPOSITORY_INDEX_NAME = 'idx_repository_checksum_mismatch'
  WIKI_INDEX_NAME = 'idx_wiki_checksum_mismatch'

  disable_ddl_transaction!

  def up
    add_concurrent_index(
      :project_registry,
      :project_id,
      name: REPOSITORY_INDEX_NAME,
      where: 'repository_checksum_mismatch = true'
    )

    add_concurrent_index(
      :project_registry,
      :project_id,
      name: WIKI_INDEX_NAME,
      where: 'wiki_checksum_mismatch = true'
    )
  end

  def down
    remove_concurrent_index_by_name(:project_registry, REPOSITORY_INDEX_NAME)
    remove_concurrent_index_by_name(:project_registry, WIKI_INDEX_NAME)
  end
end
