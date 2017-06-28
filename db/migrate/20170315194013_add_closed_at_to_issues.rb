# rubocop:disable Migration/Datetime
class AddClosedAtToIssues < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :issues, :closed_at, :datetime
  end
end
