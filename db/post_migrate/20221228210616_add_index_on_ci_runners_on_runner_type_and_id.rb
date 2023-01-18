# frozen_string_literal: true

class AddIndexOnCiRunnersOnRunnerTypeAndId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  OLD_INDEX_NAME = 'index_ci_runners_on_runner_type'
  NEW_INDEX_NAME = 'index_ci_runners_on_runner_type_and_id'

  def up
    add_concurrent_index :ci_runners, [:runner_type, :id], name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :ci_runners, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :ci_runners, :runner_type, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :ci_runners, NEW_INDEX_NAME
  end
end
