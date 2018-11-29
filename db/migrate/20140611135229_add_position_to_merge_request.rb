# rubocop:disable all
class AddPositionToMergeRequest < ActiveRecord::Migration[4.2]
  def change
    add_column :merge_requests, :position, :integer, default: 0
  end
end
