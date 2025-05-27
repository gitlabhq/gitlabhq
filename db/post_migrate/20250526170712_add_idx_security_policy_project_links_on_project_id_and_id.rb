# frozen_string_literal: true

class AddIdxSecurityPolicyProjectLinksOnProjectIdAndId < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  INDEX_NAME = 'idx_security_policy_project_links_on_project_id_and_id'

  def up
    add_concurrent_index :security_policy_project_links, [:project_id, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :security_policy_project_links, INDEX_NAME
  end
end
