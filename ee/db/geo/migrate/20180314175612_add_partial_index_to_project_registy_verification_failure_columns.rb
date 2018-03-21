class AddPartialIndexToProjectRegistyVerificationFailureColumns < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  REPOSITORY_INDEX_NAME = 'idx_project_registry_on_repository_failure_partial'
  WIKI_INDEX_NAME = 'idx_project_registry_on_wiki_failure_partial'

  disable_ddl_transaction!

  def up
    unless index_exists?(:project_registry, :project_id, name: REPOSITORY_INDEX_NAME)
      add_concurrent_index(:project_registry, :project_id, name: REPOSITORY_INDEX_NAME, where: 'last_repository_verification_failure IS NOT NULL')
    end

    unless index_exists?(:project_registry, :project_id, name: WIKI_INDEX_NAME)
      add_concurrent_index(:project_registry, :project_id, name: WIKI_INDEX_NAME, where: 'last_wiki_verification_failure IS NOT NULL')
    end
  end

  def down
    if index_exists?(:project_registry, :project_id, name: REPOSITORY_INDEX_NAME)
      remove_concurrent_index_by_name(:project_registry, REPOSITORY_INDEX_NAME)
    end

    if index_exists?(:project_registry, :project_id, name: WIKI_INDEX_NAME)
      remove_concurrent_index_by_name(:project_registry, WIKI_INDEX_NAME)
    end
  end
end
