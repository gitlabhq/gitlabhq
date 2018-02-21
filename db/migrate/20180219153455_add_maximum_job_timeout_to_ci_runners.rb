class AddMaximumJobTimeoutToCiRunners < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column :ci_runners, :maximum_job_timeout, :integer
  end

  def down
    remove_column :ci_runners, :maximum_job_timeout
  end
end
