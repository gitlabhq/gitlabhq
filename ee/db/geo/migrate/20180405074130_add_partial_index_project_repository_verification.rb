class AddPartialIndexProjectRepositoryVerification < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  REPO_INDEX_NAME = 'idx_project_registry_on_repo_checksums_and_failure_partial'
  WIKI_INDEX_NAME = 'idx_project_registry_on_wiki_checksums_and_failure_partial'

  disable_ddl_transaction!

  def up
    add_concurrent_index(:project_registry,
      [:project_id],
      name: REPO_INDEX_NAME,
      where: 'repository_verification_checksum_sha IS NULL AND last_repository_verification_failure IS NULL'
    )

    add_concurrent_index(:project_registry,
    [:project_id],
      name: WIKI_INDEX_NAME,
      where: 'wiki_verification_checksum_sha IS NULL AND last_wiki_verification_failure IS NULL'
    )
  end

  def down
    remove_concurrent_index_by_name(:project_registry, REPO_INDEX_NAME)
    remove_concurrent_index_by_name(:project_registry, WIKI_INDEX_NAME)
  end
end
