# frozen_string_literal: true

class AddIndexToCiTriggersToken < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_triggers_on_token'

  def up
    add_concurrent_index :ci_triggers, :token, unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name(:ci_triggers, INDEX_NAME)
  end
end
