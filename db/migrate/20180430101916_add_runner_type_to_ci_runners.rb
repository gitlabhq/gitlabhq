class AddRunnerTypeToCiRunners < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_runners, :runner_type, :smallint
  end
end
