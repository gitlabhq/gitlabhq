class AddPartialIndexToProjectRepositoryStatesChecksumColumns < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'idx_repository_states_on_checksums_partial'

  disable_ddl_transaction!

  def up
    unless index_exists?(:project_repository_states, [:repository_verification_checksum, :wiki_verification_checksum], name: INDEX_NAME)
      add_concurrent_index(:project_repository_states,
        [:repository_verification_checksum, :wiki_verification_checksum],
        name: INDEX_NAME,
        length: Gitlab::Database.mysql? ? 20 : nil,
        where: 'repository_verification_checksum IS NULL OR wiki_verification_checksum IS NULL'
      )
    end
  end

  def down
    if index_exists?(:project_repository_states, [:repository_verification_checksum, :wiki_verification_checksum], name: INDEX_NAME)
      remove_concurrent_index_by_name(:project_repository_states, INDEX_NAME)
    end
  end
end
