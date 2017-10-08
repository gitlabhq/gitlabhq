class AddRefToTriggers < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_triggers, :ref, :string
  end
end
