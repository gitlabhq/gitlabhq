class ChangeLockVersionNotNull < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    change_column_null :issues, :lock_version, true
    change_column_null :merge_requests, :lock_version, true
  end

  def down
  end
end
