class AddMaximumJobTimeoutToCiRunners < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_runners, :maximum_job_timeout, :integer
  end
end
