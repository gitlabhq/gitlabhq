# frozen_string_literal: true

class RemoveMergeRequestDiffCommitColumns < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  COLUMNS = %i[author_name author_email committer_name committer_email].freeze

  def change
    COLUMNS.each do |column|
      remove_column(:merge_request_diff_commits, column, :text)
    end
  end
end
