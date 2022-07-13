# frozen_string_literal: true

class AddCompositeIndexForProtectedEnvironments < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  # skips the `required_` part because index limit is 63 characters
  INDEX_NAME = 'index_protected_environments_on_approval_count_and_created_at'

  def up
    add_concurrent_index :protected_environments, %i[required_approval_count created_at], name: INDEX_NAME
  end

  def down
    remove_concurrent_index :protected_environments, %i[required_approval_count created_at], name: INDEX_NAME
  end
end
