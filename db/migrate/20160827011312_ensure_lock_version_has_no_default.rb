class EnsureLockVersionHasNoDefault < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    change_column_default :issues, :lock_version, nil
    change_column_default :merge_requests, :lock_version, nil

    execute('UPDATE issues SET lock_version = 1 WHERE lock_version = 0')
    execute('UPDATE merge_requests SET lock_version = 1 WHERE lock_version = 0')
  end

  def down
  end
end
