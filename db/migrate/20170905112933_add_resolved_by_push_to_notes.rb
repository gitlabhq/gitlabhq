class AddResolvedByPushToNotes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :notes, :resolved_by_push, :boolean
  end
end
