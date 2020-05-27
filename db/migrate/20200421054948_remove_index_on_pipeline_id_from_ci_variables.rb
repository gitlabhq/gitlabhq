# frozen_string_literal: true

class RemoveIndexOnPipelineIdFromCiVariables < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_ci_variables_on_project_id'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :ci_variables, INDEX_NAME
  end

  def down
    add_concurrent_index :ci_variables, :project_id, name: INDEX_NAME, where: "key = 'AUTO_DEVOPS_MODSECURITY_SEC_RULE_ENGINE'"
  end
end
