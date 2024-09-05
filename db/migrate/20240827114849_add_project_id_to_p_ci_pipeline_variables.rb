# frozen_string_literal: true

class AddProjectIdToPCiPipelineVariables < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    add_column(:p_ci_pipeline_variables, :project_id, :bigint)
  end
end
