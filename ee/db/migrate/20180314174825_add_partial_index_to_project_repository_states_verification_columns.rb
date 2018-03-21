class AddPartialIndexToProjectRepositoryStatesVerificationColumns < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  REPOSITORY_INDEX_NAME = 'idx_repository_states_on_repository_failure_partial'
  WIKI_INDEX_NAME = 'idx_repository_states_on_wiki_failure_partial'

  disable_ddl_transaction!

  def up
    unless index_exists?(:project_repository_states, :last_repository_verification_failure, name: REPOSITORY_INDEX_NAME)
      add_concurrent_index(:project_repository_states, :last_repository_verification_failure, name: REPOSITORY_INDEX_NAME, length: Gitlab::Database.mysql? ? 20 : nil, where: 'last_repository_verification_failure IS NOT NULL')
    end

    unless index_exists?(:project_repository_states, :last_wiki_verification_failure, name: WIKI_INDEX_NAME)
      add_concurrent_index(:project_repository_states, :last_wiki_verification_failure, name: WIKI_INDEX_NAME, length: Gitlab::Database.mysql? ? 20 : nil, where: 'last_wiki_verification_failure IS NOT NULL')
    end
  end

  def down
    if index_exists?(:project_repository_states, :last_repository_verification_failure, name: REPOSITORY_INDEX_NAME)
      remove_concurrent_index_by_name(:project_repository_states, REPOSITORY_INDEX_NAME)
    end

    if index_exists?(:project_repository_states, :last_wiki_verification_failure, name: WIKI_INDEX_NAME)
      remove_concurrent_index_by_name(:project_repository_states, WIKI_INDEX_NAME)
    end
  end
end
