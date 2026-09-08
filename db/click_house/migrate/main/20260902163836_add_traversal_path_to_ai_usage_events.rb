# frozen_string_literal: true

class AddTraversalPathToAiUsageEvents < ClickHouse::Migration
  def up
    # This table is written directly by GitLab, so it must work without Siphon: the DEFAULT cannot
    # resolve the org-scoped path through `namespace_traversal_paths_dict`. The `'0/'` sentinel keeps
    # rows in existing parts distinguishable from rows written with a real org-scoped path; a
    # `namespace_path` fallback would be indistinguishable from a legacy value written by a bug.
    execute <<~SQL
      ALTER TABLE ai_usage_events
        ADD COLUMN IF NOT EXISTS traversal_path String
          DEFAULT '0/' CODEC(ZSTD(3))
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ai_usage_events DROP COLUMN IF EXISTS traversal_path
    SQL
  end
end
