# frozen_string_literal: true

class AddIndexOnRunnerVersion < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_runners_on_version'

  def up
    add_concurrent_index :ci_runners, :version, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_runners, INDEX_NAME
  end
end
