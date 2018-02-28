class AddUsedTimeoutAndTimeoutSourceColumnsToCiBuilds < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_builds, :used_timeout, :integer
    add_column :ci_builds, :timeout_source, :integer
  end
end
