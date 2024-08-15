# frozen_string_literal: true

class IndexProtectedEnvironmentApprovalRulesOnProtectedEnvironmentProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  disable_ddl_transaction!

  INDEX_NAME = 'index_protected_environment_project_id_of_protected_environment'

  def up
    add_concurrent_index :protected_environment_approval_rules, :protected_environment_project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :protected_environment_approval_rules, INDEX_NAME
  end
end
