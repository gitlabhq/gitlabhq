class AddDescriptionToTriggers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_triggers, :description, :string
  end
end
