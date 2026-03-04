# frozen_string_literal: true

class AddLastUsedAtToCiRunnerControllerTokens < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  NEW_INDEX_NAME = 'index_ci_runner_controller_tokens_on_rc_id_status_last_used_at'
  OLD_INDEX_NAME = 'index_ci_runner_controller_tokens_on_rc_id_and_status'

  disable_ddl_transaction!

  def up
    add_column :ci_runner_controller_tokens, :last_used_at, :datetime_with_timezone, if_not_exists: true

    add_concurrent_index :ci_runner_controller_tokens,
      [:runner_controller_id, :status, :last_used_at],
      order: { last_used_at: 'DESC' },
      name: NEW_INDEX_NAME

    remove_concurrent_index_by_name :ci_runner_controller_tokens, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :ci_runner_controller_tokens,
      [:runner_controller_id, :status],
      name: OLD_INDEX_NAME

    remove_concurrent_index_by_name :ci_runner_controller_tokens, NEW_INDEX_NAME

    remove_column :ci_runner_controller_tokens, :last_used_at, if_exists: true
  end
end
