# frozen_string_literal: true

class CreateSecurityPipelineExecutionPolicyConfigLinks < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  POLICY_INDEX_NAME = 'index_pep_policy_config_links_security_policy_id'
  UNIQUE_INDEX_NAME = 'unique_pep_policy_config_links_project_security_policy'

  def up
    create_table :security_pipeline_execution_policy_config_links do |t|
      t.bigint :project_id, null: false
      t.bigint :security_policy_id, null: false, index: { name: POLICY_INDEX_NAME }

      t.index [:project_id, :security_policy_id], unique: true, name: UNIQUE_INDEX_NAME
    end
  end

  def down
    drop_table :security_pipeline_execution_policy_config_links
  end
end
