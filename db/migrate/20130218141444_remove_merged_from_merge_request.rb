# rubocop:disable all
class RemoveMergedFromMergeRequest < ActiveRecord::Migration[4.2]
  def up
    remove_column :merge_requests, :merged
  end

  def down
    add_column :merge_requests, :merged, :boolean, default: true, null: false
  end
end
