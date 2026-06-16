# frozen_string_literal: true

class AddLinkTypeToSiphonMergeRequestsClosingIssues < ClickHouse::Migration
  # Int8 is acceptable for an ActiveRecord enum with only a few values
  # (closes=0, mentioned=1); see spec/db/clickhouse_siphon_tables_spec.rb.
  def up
    execute <<~SQL
      ALTER TABLE siphon_merge_requests_closing_issues ADD COLUMN link_type Int8 DEFAULT 0;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_merge_requests_closing_issues DROP COLUMN link_type;
    SQL
  end
end
