# frozen_string_literal: true

class AddByteaShaColumnsToSiphonMergeRequestDiffs < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_merge_request_diffs
        ADD COLUMN IF NOT EXISTS base_commit_sha_bytea Nullable(String),
        ADD COLUMN IF NOT EXISTS start_commit_sha_bytea Nullable(String),
        ADD COLUMN IF NOT EXISTS head_commit_sha_bytea Nullable(String);
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_merge_request_diffs
        DROP COLUMN IF EXISTS base_commit_sha_bytea,
        DROP COLUMN IF EXISTS start_commit_sha_bytea,
        DROP COLUMN IF EXISTS head_commit_sha_bytea;
    SQL
  end
end
