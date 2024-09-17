# frozen_string_literal: true

class AddProjectIdToPCiJobAnnotations < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    add_column(:p_ci_job_annotations, :project_id, :bigint)
  end
end
