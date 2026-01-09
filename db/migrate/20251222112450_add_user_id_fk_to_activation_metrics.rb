# frozen_string_literal: true

class AddUserIdFkToActivationMetrics < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.8'

  def up
    add_concurrent_foreign_key :activation_metrics, :users, column: :user_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :activation_metrics, column: :user_id
    end
  end
end
