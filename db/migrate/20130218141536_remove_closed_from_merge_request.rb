# rubocop:disable all
class RemoveClosedFromMergeRequest < ActiveRecord::Migration[4.2]
  def up
    remove_column :merge_requests, :closed
  end

  def down
    add_column :merge_requests, :closed, :boolean
  end
end
