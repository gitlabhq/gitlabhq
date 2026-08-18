# frozen_string_literal: true

class AddLegacyColumnsToPartitionedMergeRequestDiffCommits < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  TABLE_NAME = :merge_request_diff_commits_b5377a7a34

  def up
    # rubocop:disable Migration/SchemaAdditionMethodsNoPost -- nothing reads or writes these columns; they
    # exist so queries stay valid once SwapMergeRequestDiffCommitsTable runs. The ALTER locks the parent and
    # every partition, so it runs in a PDM window rather than blocking a deployment.
    with_lock_retries do
      add_column TABLE_NAME, :sha, :bytea, if_not_exists: true
      # rubocop:disable Migration/AddLimitToTextColumns -- the legacy column is unbounded; a limit
      # here would add a CHECK constraint the swapped-in table must not have
      add_column TABLE_NAME, :message, :text, if_not_exists: true
      # rubocop:enable Migration/AddLimitToTextColumns
      add_column TABLE_NAME, :commit_author_id, :bigint, if_not_exists: true
      add_column TABLE_NAME, :committer_id, :bigint, if_not_exists: true
      # rubocop:disable Migration/Datetime -- must match `timestamp without time zone` on the legacy table
      add_column TABLE_NAME, :authored_date, :datetime, if_not_exists: true
      add_column TABLE_NAME, :committed_date, :datetime, if_not_exists: true
      # rubocop:enable Migration/Datetime
      add_column TABLE_NAME, :trailers, :jsonb, default: {}, if_not_exists: true
    end
    # rubocop:enable Migration/SchemaAdditionMethodsNoPost
  end

  def down
    with_lock_retries do
      remove_column TABLE_NAME, :sha, if_exists: true
      remove_column TABLE_NAME, :message, if_exists: true
      remove_column TABLE_NAME, :commit_author_id, if_exists: true
      remove_column TABLE_NAME, :committer_id, if_exists: true
      remove_column TABLE_NAME, :authored_date, if_exists: true
      remove_column TABLE_NAME, :committed_date, if_exists: true
      remove_column TABLE_NAME, :trailers, if_exists: true
    end
  end
end
