# frozen_string_literal: true

class AddExposedAsAndExposedPathsToCiJobArtifacts < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :p_ci_job_artifacts, :exposed_as, :text, if_not_exists: true
      add_column :p_ci_job_artifacts, :exposed_paths, :text, array: true, if_not_exists: true
    end

    add_text_limit :p_ci_job_artifacts, :exposed_as, 100, validate: false
  end

  def down
    with_lock_retries do
      remove_column :p_ci_job_artifacts, :exposed_as, if_exists: true
      remove_column :p_ci_job_artifacts, :exposed_paths, if_exists: true
    end
  end
end
