class AddUsedTimeoutAndTimeoutSourceColumnsToCiBuilds < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column :ci_builds, :used_timeout, :integer
    add_column :ci_builds, :timeout_source, :string
  end

  def down
    remove_column :ci_builds, :used_timeout
    remove_column :ci_builds, :timeout_source
  end
end
