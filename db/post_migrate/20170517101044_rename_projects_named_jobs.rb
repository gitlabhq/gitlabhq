class RenameProjectsNamedJobs < ActiveRecord::Migration
  include Gitlab::Database::RenameReservedPathsMigration::V1

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    rename_wildcard_paths('jobs')
  end

  def down
  end
end
