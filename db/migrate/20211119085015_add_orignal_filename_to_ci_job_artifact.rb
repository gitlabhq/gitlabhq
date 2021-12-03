# frozen_string_literal: true

class AddOrignalFilenameToCiJobArtifact < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20211119085036_add_text_limit_to_job_artifact_original_filename.rb
  def up
    add_column :ci_job_artifacts, :original_filename, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns

  def down
    remove_column :ci_job_artifacts, :original_filename, :text
  end
end
