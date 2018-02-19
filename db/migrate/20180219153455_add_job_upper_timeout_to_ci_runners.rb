class AddJobUpperTimeoutToCiRunners < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column :ci_runners, :job_upper_timeout, :integer
  end

  def down
    remove_column :ci_runners, :job_upper_timeout
  end
end
