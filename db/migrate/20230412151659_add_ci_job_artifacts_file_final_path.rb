# frozen_string_literal: true

class AddCiJobArtifactsFileFinalPath < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in db/post_migrate/20230412152538_add_text_limit_to_ci_job_artifacts_file_final_path.rb
  def change
    add_column :ci_job_artifacts, :file_final_path, :text, null: true
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
