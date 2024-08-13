# frozen_string_literal: true

class AddEncodedFilePathToMergeRequestContextCommitDiffFiles < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    add_column :merge_request_context_commit_diff_files, :encoded_file_path, :boolean, default: false, null: false
  end
end
