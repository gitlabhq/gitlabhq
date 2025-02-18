# frozen_string_literal: true

class ValidateNotNullConstraintForPipelineMessages < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def up
    validate_not_null_constraint(:ci_pipeline_messages, :project_id)
  end

  def down
    # no-op
  end
end
