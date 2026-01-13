# frozen_string_literal: true

class AddStatusToCiRunnerControllerTokens < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.8'

  INDEX_NAME = 'index_ci_runner_controller_tokens_on_rc_id_and_status'
  OLD_INDEX_NAME = 'index_ci_rac_tokens_on_rac_id'

  def up
    add_column :ci_runner_controller_tokens, :status, :integer, limit: 2, default: 0, null: false

    add_concurrent_index :ci_runner_controller_tokens, [:runner_controller_id, :status], name: INDEX_NAME
    remove_concurrent_index_by_name :ci_runner_controller_tokens, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :ci_runner_controller_tokens, :runner_controller_id, name: OLD_INDEX_NAME

    remove_column :ci_runner_controller_tokens, :status
  end
end
