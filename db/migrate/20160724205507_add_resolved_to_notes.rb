# rubocop:disable Migration/Datetime
class AddResolvedToNotes < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :notes, :resolved_at, :datetime
    add_column :notes, :resolved_by_id, :integer
  end
end
