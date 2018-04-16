class AddPartialIndexToProjectRegistyChecksumShaColumns < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  REPOSITORY_INDEX_NAME = 'idx_project_registry_on_repository_checksum_sha_partial'
  WIKI_INDEX_NAME = 'idx_project_registry_on_wiki_checksum_sha_partial'

  disable_ddl_transaction!

  def up
    add_concurrent_index(:project_registry, :repository_verification_checksum_sha, name: REPOSITORY_INDEX_NAME, where: 'repository_verification_checksum_sha IS NULL')
    add_concurrent_index(:project_registry, :wiki_verification_checksum_sha, name: WIKI_INDEX_NAME, where: 'wiki_verification_checksum_sha IS NULL')
  end

  def down
    remove_concurrent_index_by_name(:project_registry, REPOSITORY_INDEX_NAME)
    remove_concurrent_index_by_name(:project_registry, WIKI_INDEX_NAME)
  end
end
