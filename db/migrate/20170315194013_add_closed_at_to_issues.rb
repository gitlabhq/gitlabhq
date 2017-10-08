# rubocop:disable Migration/Datetime
class AddClosedAtToIssues < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    add_column :issues, :closed_at, :datetime
  end
end
