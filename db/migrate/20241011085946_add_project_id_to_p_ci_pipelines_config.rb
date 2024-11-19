# frozen_string_literal: true

class AddProjectIdToPCiPipelinesConfig < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    add_column(:p_ci_pipelines_config, :project_id, :bigint)
  end
end
