# frozen_string_literal: true

class AddUniqueIndexOnCiRunnerVersionsOnStatusAndVersion < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_runner_versions_on_unique_status_and_version'

  def up
    add_concurrent_index :ci_runner_versions, [:status, :version], name: INDEX_NAME, unique: true
  end

  def down
    remove_concurrent_index_by_name :ci_runner_versions, INDEX_NAME
  end
end
