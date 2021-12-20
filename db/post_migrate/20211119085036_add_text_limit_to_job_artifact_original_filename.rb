# frozen_string_literal: true

class AddTextLimitToJobArtifactOriginalFilename < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :ci_job_artifacts, :original_filename, 512
  end

  def down
    remove_text_limit :ci_job_artifacts, :original_filename
  end
end
