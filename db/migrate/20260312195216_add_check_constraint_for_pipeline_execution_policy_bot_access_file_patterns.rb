# frozen_string_literal: true

class AddCheckConstraintForPipelineExecutionPolicyBotAccessFilePatterns < Gitlab::Database::Migration[2.3]
  milestone '18.11'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_project_settings_pep_bot_access_file_patterns_size'

  def up
    add_check_constraint :project_settings,
      'CARDINALITY(pipeline_execution_policy_bot_access_file_patterns) <= 20',
      CONSTRAINT_NAME,
      validate: false
  end

  def down
    remove_check_constraint :project_settings, CONSTRAINT_NAME
  end
end
