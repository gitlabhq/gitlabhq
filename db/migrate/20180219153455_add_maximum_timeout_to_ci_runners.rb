class AddMaximumTimeoutToCiRunners < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_runners, :maximum_timeout, :integer
  end
end
