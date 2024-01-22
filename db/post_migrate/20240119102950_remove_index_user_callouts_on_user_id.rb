# frozen_string_literal: true

class RemoveIndexUserCalloutsOnUserId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.9'

  INDEX_NAME = 'index_user_callouts_on_user_id'

  def up
    remove_concurrent_index_by_name(:user_callouts, INDEX_NAME)
  end

  def down
    add_concurrent_index(:user_callouts, :user_id, name: INDEX_NAME)
  end
end
