class FixPartialIndexToProjectRepositoryStatesChecksumColumns < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  OLD_INDEX_NAME = 'idx_repository_states_on_checksums_partial'
  NEW_INDEX_NAME = 'idx_repository_states_outdated_checksums'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name(:project_repository_states, OLD_INDEX_NAME)

    add_concurrent_index(:project_repository_states,
      :project_id,
      name: NEW_INDEX_NAME,
      where: '(repository_verification_checksum IS NULL AND last_repository_verification_failure is NULL) OR (wiki_verification_checksum IS NULL AND last_wiki_verification_failure IS NULL)'
                        )
  end

  def down
    remove_concurrent_index_by_name(:project_repository_states, NEW_INDEX_NAME)

    add_concurrent_index(:project_repository_states,
      [:repository_verification_checksum, :wiki_verification_checksum],
      name: OLD_INDEX_NAME,
      length: Gitlab::Database.mysql? ? 20 : nil,
      where: 'repository_verification_checksum IS NULL OR wiki_verification_checksum IS NULL'
                        )
  end
end
