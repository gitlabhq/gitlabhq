# frozen_string_literal: true

class AddGeneratedToMergeRequestContextCommitDiffFiles < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  enable_lock_retries!

  def change
    add_column :merge_request_context_commit_diff_files, :generated, :boolean
  end
end
