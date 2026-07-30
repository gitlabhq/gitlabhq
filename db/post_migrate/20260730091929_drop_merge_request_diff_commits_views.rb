# frozen_string_literal: true

class DropMergeRequestDiffCommitsViews < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  VIEW_PREFIX = 'merge_request_diff_commits_views'

  def up
    return unless Gitlab.com_except_jh?

    connection.select_values(
      "SELECT viewname FROM pg_views WHERE viewname LIKE '#{VIEW_PREFIX}_%'"
    ).each do |view_name|
      execute("DROP VIEW IF EXISTS #{connection.quote_table_name(view_name)}")
    end
  end

  def down
    # no-op: views were temporary aid for BackfillMergeRequestDiffCommitsToPartitioned; recreating them not necessary
  end
end
