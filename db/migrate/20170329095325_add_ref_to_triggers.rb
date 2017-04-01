class AddRefToTriggers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_triggers, :ref, :string
  end
end
