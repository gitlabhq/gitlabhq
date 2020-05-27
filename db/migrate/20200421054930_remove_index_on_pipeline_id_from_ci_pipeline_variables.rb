# frozen_string_literal: true

class RemoveIndexOnPipelineIdFromCiPipelineVariables < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_ci_pipeline_variables_on_pipeline_id'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :ci_pipeline_variables, INDEX_NAME
  end

  def down
    add_concurrent_index :ci_pipeline_variables, :pipeline_id, name: INDEX_NAME, where: "key = 'AUTO_DEVOPS_MODSECURITY_SEC_RULE_ENGINE'"
  end
end
