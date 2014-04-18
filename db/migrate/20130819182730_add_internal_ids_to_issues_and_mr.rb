class AddInternalIdsToIssuesAndMr < ActiveRecord::Migration
  def change
    add_column :issues, :iid, :integer
    add_column :merge_requests, :iid, :integer
  end
end
