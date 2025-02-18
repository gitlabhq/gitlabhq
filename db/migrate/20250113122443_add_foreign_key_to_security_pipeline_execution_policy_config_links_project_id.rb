# frozen_string_literal: true

class AddForeignKeyToSecurityPipelineExecutionPolicyConfigLinksProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :security_pipeline_execution_policy_config_links, :projects, column: :project_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :security_pipeline_execution_policy_config_links, column: :project_id
    end
  end
end
