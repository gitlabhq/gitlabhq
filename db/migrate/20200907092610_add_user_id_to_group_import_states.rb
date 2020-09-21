# frozen_string_literal: true

class AddUserIdToGroupImportStates < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless column_exists?(:group_import_states, :user_id)
      with_lock_retries do
        add_column :group_import_states, :user_id, :bigint
      end
    end

    add_concurrent_foreign_key :group_import_states, :users, column: :user_id, on_delete: :cascade
    add_concurrent_index :group_import_states, :user_id, where: 'user_id IS NOT NULL', name: 'index_group_import_states_on_user_id'
  end

  def down
    with_lock_retries do
      remove_column :group_import_states, :user_id
    end
  end
end
