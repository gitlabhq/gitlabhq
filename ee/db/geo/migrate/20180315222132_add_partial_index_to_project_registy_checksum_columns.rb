class AddPartialIndexToProjectRegistyChecksumColumns < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  REPOSITORY_INDEX_NAME = 'idx_project_registry_on_repository_checksum_partial'
  WIKI_INDEX_NAME = 'idx_project_registry_on_wiki_checksum_partial'

  disable_ddl_transaction!

  def up
    unless index_exists?(:project_registry, :repository_verification_checksum, name: REPOSITORY_INDEX_NAME)
      add_concurrent_index(:project_registry, :repository_verification_checksum, name: REPOSITORY_INDEX_NAME, where: 'repository_verification_checksum IS NULL')
    end

    unless index_exists?(:project_registry, :wiki_verification_checksum, name: WIKI_INDEX_NAME)
      add_concurrent_index(:project_registry, :wiki_verification_checksum, name: WIKI_INDEX_NAME, where: 'wiki_verification_checksum IS NULL')
    end
  end

  def down
    if index_exists?(:project_registry, :repository_verification_checksum, name: REPOSITORY_INDEX_NAME)
      remove_concurrent_index_by_name(:project_registry, REPOSITORY_INDEX_NAME)
    end

    if index_exists?(:project_registry, :wiki_verification_checksum, name: WIKI_INDEX_NAME)
      remove_concurrent_index_by_name(:project_registry, WIKI_INDEX_NAME)
    end
  end
end
