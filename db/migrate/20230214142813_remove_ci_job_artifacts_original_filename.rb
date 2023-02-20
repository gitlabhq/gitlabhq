# frozen_string_literal: true

class RemoveCiJobArtifactsOriginalFilename < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    # This column has never been used and has always been under ignore_column since it was added.
    # We're doing the removal of the ignore_column in the same MR with this migration and this
    # is why we are not doing this in post migrate.
    remove_column :ci_job_artifacts, :original_filename, :text # rubocop:disable Migration/RemoveColumn
  end

  def down
    add_column :ci_job_artifacts, :original_filename, :text
  end
end
