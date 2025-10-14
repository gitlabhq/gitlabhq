# frozen_string_literal: true

class TriggerTokenExpirationIndex < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_triggers_on_expires_at'

  def up
    add_concurrent_index :ci_triggers, :expires_at, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_triggers, name: INDEX_NAME
  end
end
