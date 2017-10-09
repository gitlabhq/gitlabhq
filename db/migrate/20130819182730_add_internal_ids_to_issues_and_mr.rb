# rubocop:disable all
class AddInternalIdsToIssuesAndMr < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :iid, :integer
    add_column :merge_requests, :iid, :integer
  end
end
