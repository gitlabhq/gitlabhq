class DropUserActivitiesTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # This migration is a no-op. It just exists to match EE.
  def change
  end
end
