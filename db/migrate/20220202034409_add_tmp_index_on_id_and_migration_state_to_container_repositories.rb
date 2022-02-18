# frozen_string_literal: true

class AddTmpIndexOnIdAndMigrationStateToContainerRepositories < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'tmp_index_container_repositories_on_id_migration_state'

  disable_ddl_transaction!

  # Temporary index to be removed https://gitlab.com/gitlab-org/gitlab/-/issues/351783
  def up
    add_concurrent_index :container_repositories, [:id, :migration_state], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :container_repositories, INDEX_NAME
  end
end
