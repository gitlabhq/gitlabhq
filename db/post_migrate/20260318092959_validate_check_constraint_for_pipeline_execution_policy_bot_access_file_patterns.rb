# frozen_string_literal: true

class ValidateCheckConstraintForPipelineExecutionPolicyBotAccessFilePatterns < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  CONSTRAINT_NAME = 'check_project_settings_pep_bot_access_file_patterns_size'

  def up
    validate_check_constraint :project_settings, CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end
