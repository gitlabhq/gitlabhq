# frozen_string_literal: true

class DeleteExperimentUserForeignKeys < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :experiment_users, :experiments, name: 'fk_rails_56d4708b4a'
    end

    with_lock_retries do
      remove_foreign_key_if_exists :experiment_users, :users, name: 'fk_rails_fd805f771a'
    end
  end

  def down
    add_concurrent_foreign_key :experiment_users, :experiments, column: :experiment_id, name: 'fk_rails_56d4708b4a'
    add_concurrent_foreign_key :experiment_users, :users, column: :user_id, name: 'fk_rails_fd805f771a'
  end
end
