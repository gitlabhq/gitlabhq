# frozen_string_literal: true

class ValidateCiPipelineProjectIdNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def up
    validate_not_null_constraint :ci_pipelines, :project_id
  end

  def down
    # no-op
  end
end
