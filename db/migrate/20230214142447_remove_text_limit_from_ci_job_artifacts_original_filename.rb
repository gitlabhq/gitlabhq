# frozen_string_literal: true

class RemoveTextLimitFromCiJobArtifactsOriginalFilename < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    # In preparation for 20230214142813_remove_ci_job_artifacts_original_filename.rb
    # We first remove the text limit before removing the column.
    # This is to properly reverse the 2-step migration to add a text column with limit
    # https://docs.gitlab.com/ee/development/database/strings_and_the_text_data_type.html#add-a-text-column-to-an-existing-table
    remove_text_limit :ci_job_artifacts, :original_filename
  end

  def down
    add_text_limit :ci_job_artifacts, :original_filename, 512
  end
end
