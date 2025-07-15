# frozen_string_literal: true

class AdjustSiphonMergeRequests < ClickHouse::Migration
  def up
    execute "ALTER TABLE siphon_merge_requests MODIFY COLUMN title String DEFAULT ''"
    execute "ALTER TABLE siphon_merge_requests MODIFY COLUMN description String DEFAULT ''"

    execute "ALTER TABLE siphon_merge_requests MODIFY COLUMN created_at DateTime64(6, 'UTC') DEFAULT NOW()"
    execute "ALTER TABLE siphon_merge_requests MODIFY COLUMN updated_at DateTime64(6, 'UTC') DEFAULT NOW()"

    execute "ALTER TABLE siphon_merge_requests DROP COLUMN IF EXISTS title_html"
    execute "ALTER TABLE siphon_merge_requests DROP COLUMN IF EXISTS description_html"

    execute "ALTER TABLE siphon_merge_requests MODIFY COLUMN lock_version Int64"
  end

  def down
    execute "ALTER TABLE siphon_merge_requests MODIFY COLUMN title Nullable(String)"

    if column_default_present?('siphon_merge_requests', 'title')
      execute "ALTER TABLE siphon_merge_requests MODIFY COLUMN title REMOVE DEFAULT"
    end

    execute "ALTER TABLE siphon_merge_requests MODIFY COLUMN description Nullable(String)"

    if column_default_present?('siphon_merge_requests', 'description')
      execute "ALTER TABLE siphon_merge_requests MODIFY COLUMN description REMOVE DEFAULT"
    end

    execute "ALTER TABLE siphon_merge_requests MODIFY COLUMN created_at Nullable(DateTime64(6, 'UTC'))"

    if column_default_present?('siphon_merge_requests', 'created_at')
      execute "ALTER TABLE siphon_merge_requests MODIFY COLUMN created_at REMOVE DEFAULT"
    end

    execute "ALTER TABLE siphon_merge_requests MODIFY COLUMN updated_at Nullable(DateTime64(6, 'UTC'))"

    if column_default_present?('siphon_merge_requests', 'updated_at')
      execute "ALTER TABLE siphon_merge_requests MODIFY COLUMN updated_at REMOVE DEFAULT"
    end

    execute "ALTER TABLE siphon_merge_requests ADD COLUMN IF NOT EXISTS title_html Nullable(String)"
    execute "ALTER TABLE siphon_merge_requests ADD COLUMN IF NOT EXISTS description_html Nullable(String)"

    execute "ALTER TABLE siphon_merge_requests MODIFY COLUMN lock_version Nullable(Int64)"
  end
end
