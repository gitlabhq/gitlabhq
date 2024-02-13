# frozen_string_literal: true

class RemoveIndexProtectedEnvironmentsOnProjectId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.9'

  INDEX_NAME = 'index_protected_environments_on_project_id'

  def up
    remove_concurrent_index_by_name :protected_environments, name: INDEX_NAME
  end

  def down
    add_concurrent_index :protected_environments, :project_id, name: INDEX_NAME
  end
end
