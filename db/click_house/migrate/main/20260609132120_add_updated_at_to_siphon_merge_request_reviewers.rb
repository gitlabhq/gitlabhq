# frozen_string_literal: true

class AddUpdatedAtToSiphonMergeRequestReviewers < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_merge_request_reviewers
      ADD COLUMN IF NOT EXISTS updated_at Nullable(DateTime64(6, 'UTC')) CODEC(Delta(8), ZSTD(1))
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_merge_request_reviewers
      DROP COLUMN IF EXISTS updated_at
    SQL
  end
end
