# frozen_string_literal: true

class DropNotNullConstraintFromMergeRequestDiffCommits < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  def up
    change_column_null :merge_request_diff_commits, :sha, true
    change_column_null :merge_request_diff_commits, :trailers, true
  end

  def down
    # no-op
    #
    # Setting the columns back to be non-nullable and ensuring that data doesn't
    # really have any NULL values for these columns will take time since the
    # table is very large.
    #
    # At this point, we're not setting these columns to have `NULL` values yet.
    # That will be done later in https://gitlab.com/gitlab-org/gitlab/-/issues/527240.
  end
end
