# frozen_string_literal: true

class AddIndexForDormantUsers < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = 'index_users_on_id_and_last_activity_on_for_non_internal_active'

  disable_ddl_transaction!

  def up
    index_condition = "state = 'active' AND (users.user_type IS NULL OR users.user_type IN (NULL, 6, 4))"

    add_concurrent_index :users, [:id, :last_activity_on], where: index_condition, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :users, INDEX_NAME
  end
end
