# frozen_string_literal: true

class RemoveTokenFromCiTrigger < Gitlab::Database::Migration[2.3]
  milestone '18.8'
  disable_ddl_transaction!

  def up
    remove_column :ci_triggers, :token, if_exists: true
  end

  def down
    add_column :ci_triggers, :token, :string, if_not_exists: true
    add_concurrent_index :ci_triggers, :token, unique: true,
      name: 'index_ci_triggers_on_token'
  end
end
