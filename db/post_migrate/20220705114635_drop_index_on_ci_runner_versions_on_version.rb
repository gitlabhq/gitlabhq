# frozen_string_literal: true

class DropIndexOnCiRunnerVersionsOnVersion < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_runner_versions_on_version'

  def up
    remove_concurrent_index_by_name :ci_runner_versions, INDEX_NAME
  end

  def down
    add_concurrent_index :ci_runner_versions, :version, name: INDEX_NAME
  end
end
