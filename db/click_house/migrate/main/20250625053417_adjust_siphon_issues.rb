# frozen_string_literal: true

class AdjustSiphonIssues < ClickHouse::Migration
  def up
    # Avoid nullable so later we can create full-text search indexes
    execute "ALTER TABLE siphon_issues MODIFY COLUMN title String DEFAULT ''"
    execute "ALTER TABLE siphon_issues MODIFY COLUMN description String DEFAULT ''"

    # Set default for timestamp columns
    execute "ALTER TABLE siphon_issues MODIFY COLUMN created_at DateTime64(6, 'UTC') DEFAULT NOW()"
    execute "ALTER TABLE siphon_issues MODIFY COLUMN updated_at DateTime64(6, 'UTC') DEFAULT NOW()"

    # Not relevant to analytics
    execute "ALTER TABLE siphon_issues DROP COLUMN IF EXISTS title_html"
    execute "ALTER TABLE siphon_issues DROP COLUMN IF EXISTS description_html"

    # These columns have NOT NULL check constraint
    execute "ALTER TABLE siphon_issues MODIFY COLUMN work_item_type_id Int64"
    execute "ALTER TABLE siphon_issues MODIFY COLUMN namespace_id Int64"
    execute "ALTER TABLE siphon_issues MODIFY COLUMN lock_version Int64"
  end

  def down
    execute "ALTER TABLE siphon_issues MODIFY COLUMN title Nullable(String)"

    if column_default_present?('siphon_issues', 'title')
      execute "ALTER TABLE siphon_issues MODIFY COLUMN title REMOVE DEFAULT"
    end

    execute "ALTER TABLE siphon_issues MODIFY COLUMN description Nullable(String)"

    if column_default_present?('siphon_issues', 'description')
      execute "ALTER TABLE siphon_issues MODIFY COLUMN description REMOVE DEFAULT"
    end

    execute "ALTER TABLE siphon_issues MODIFY COLUMN created_at Nullable(DateTime64(6, 'UTC'))"

    if column_default_present?('siphon_issues', 'created_at')
      execute "ALTER TABLE siphon_issues MODIFY COLUMN created_at REMOVE DEFAULT"
    end

    execute "ALTER TABLE siphon_issues MODIFY COLUMN updated_at Nullable(DateTime64(6, 'UTC'))"

    if column_default_present?('siphon_issues', 'updated_at')
      execute "ALTER TABLE siphon_issues MODIFY COLUMN updated_at REMOVE DEFAULT"
    end

    execute "ALTER TABLE siphon_issues ADD COLUMN IF NOT EXISTS title_html Nullable(String)"
    execute "ALTER TABLE siphon_issues ADD COLUMN IF NOT EXISTS description_html Nullable(String)"

    execute "ALTER TABLE siphon_issues MODIFY COLUMN work_item_type_id Nullable(Int64)"
    execute "ALTER TABLE siphon_issues MODIFY COLUMN namespace_id Nullable(Int64)"
    execute "ALTER TABLE siphon_issues MODIFY COLUMN lock_version Nullable(Int64)"
  end
end
