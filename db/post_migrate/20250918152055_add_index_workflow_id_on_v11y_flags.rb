# frozen_string_literal: true

class AddIndexWorkflowIdOnV11yFlags < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  INDEX_NAME = :index_vulnerability_flags_on_workflow_id

  def up
    add_concurrent_index :vulnerability_flags, :workflow_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :vulnerability_flags, INDEX_NAME
  end
end
