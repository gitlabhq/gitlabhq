class AddResolvedByPushToNotes < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :notes, :resolved_by_push, :boolean
  end
end
