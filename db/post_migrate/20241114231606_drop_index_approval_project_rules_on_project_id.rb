# frozen_string_literal: true

class DropIndexApprovalProjectRulesOnProjectId < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_approval_project_rules_on_project_id'

  disable_ddl_transaction!
  milestone '17.7'

  def up
    remove_concurrent_index_by_name :approval_project_rules, INDEX_NAME
  end

  def down
    add_concurrent_index :approval_project_rules, :project_id, name: INDEX_NAME
  end
end
