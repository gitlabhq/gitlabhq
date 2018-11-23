class DropUserActivitiesTable < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # This migration is a no-op. It just exists to match EE.
  def change
  end
end
