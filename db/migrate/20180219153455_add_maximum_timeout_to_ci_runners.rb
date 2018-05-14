class AddMaximumTimeoutToCiRunners < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_runners, :maximum_timeout, :integer
  end
end
