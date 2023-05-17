# frozen_string_literal: true

class ValidateCiJobArtifactsFileFinalPath < Gitlab::Database::Migration[2.1]
  def up
    constraint_name = text_limit_name(:ci_job_artifacts, :file_final_path)
    validate_check_constraint :ci_job_artifacts, constraint_name
  end

  # No-op
  def down; end
end
