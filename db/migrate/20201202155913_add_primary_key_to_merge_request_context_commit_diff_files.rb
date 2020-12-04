# frozen_string_literal: true

class AddPrimaryKeyToMergeRequestContextCommitDiffFiles < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    execute(<<~SQL)
      DELETE FROM merge_request_context_commit_diff_files
      WHERE merge_request_context_commit_id IS NULL;

      DELETE FROM merge_request_context_commit_diff_files df1
      USING merge_request_context_commit_diff_files df2
      WHERE df1.ctid < df2.ctid
        AND df1.merge_request_context_commit_id = df2.merge_request_context_commit_id
        AND df1.relative_order = df2.relative_order;

      ALTER TABLE merge_request_context_commit_diff_files
      ADD CONSTRAINT merge_request_context_commit_diff_files_pkey PRIMARY KEY (merge_request_context_commit_id, relative_order);
    SQL
  end

  def down
    execute(<<~SQL)
      ALTER TABLE merge_request_context_commit_diff_files
      DROP CONSTRAINT merge_request_context_commit_diff_files_pkey,
      ALTER COLUMN merge_request_context_commit_id DROP NOT NULL
    SQL
  end
end
