# rubocop:disable all
class AddDeleteAtToMergeRequests < ActiveRecord::Migration[4.2]
  def change
    add_column :merge_requests, :deleted_at, :datetime
    add_index :merge_requests, :deleted_at
  end
end
