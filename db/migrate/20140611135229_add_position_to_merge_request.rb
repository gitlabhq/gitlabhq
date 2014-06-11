class AddPositionToMergeRequest < ActiveRecord::Migration
  def change
    add_column :merge_requests, :position, :integer, default: 0
  end
end
