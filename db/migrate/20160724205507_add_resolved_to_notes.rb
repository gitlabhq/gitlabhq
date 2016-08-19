class AddResolvedToNotes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :notes, :resolved_at, :datetime
    add_column :notes, :resolved_by_id, :integer
  end
end
