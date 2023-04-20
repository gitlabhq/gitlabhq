# frozen_string_literal: true

class AddTextLimitToCiJobArtifactsFileFinalPath < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :ci_job_artifacts, :file_final_path, 1024, constraint_name: constraint_name, validate: false
    prepare_async_check_constraint_validation(:ci_job_artifacts, name: constraint_name)
  end

  def down
    unprepare_async_check_constraint_validation(:ci_job_artifacts, name: constraint_name)
    remove_text_limit :ci_job_artifacts, :file_final_path
  end

  private

  def constraint_name
    text_limit_name(:ci_job_artifacts, :file_final_path)
  end
end
