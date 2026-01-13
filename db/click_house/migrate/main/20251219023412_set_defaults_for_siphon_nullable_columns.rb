# frozen_string_literal: true

# ClickHouse 25.12 requires explicit DEFAULT when converting nullable to non-nullable.
# This migration adds DEFAULT expressions for environments where earlier migrations ran
# before 25.12 and left columns without defaults.
class SetDefaultsForSiphonNullableColumns < ClickHouse::Migration
  def up
    execute "ALTER TABLE siphon_issues MODIFY COLUMN work_item_type_id Int64 DEFAULT 0"
    execute "ALTER TABLE siphon_issues MODIFY COLUMN namespace_id Int64 DEFAULT 0"
    execute "ALTER TABLE siphon_issues MODIFY COLUMN lock_version Int64 DEFAULT 0"

    execute "ALTER TABLE siphon_namespaces MODIFY COLUMN organization_id Int64 DEFAULT 0"

    execute "ALTER TABLE siphon_merge_requests MODIFY COLUMN lock_version Int64 DEFAULT 0"
  end

  def down
    execute "ALTER TABLE siphon_issues MODIFY COLUMN work_item_type_id Int64"
    execute "ALTER TABLE siphon_issues MODIFY COLUMN namespace_id Int64"
    execute "ALTER TABLE siphon_issues MODIFY COLUMN lock_version Int64"

    execute "ALTER TABLE siphon_namespaces MODIFY COLUMN organization_id Int64"

    execute "ALTER TABLE siphon_merge_requests MODIFY COLUMN lock_version Int64"
  end
end
