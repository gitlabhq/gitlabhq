# rubocop:disable all
class AddIndexMergeRequestDiffsOnMergeRequestId < ActiveRecord::Migration[4.2]
  def change
    add_index :merge_request_diffs, :merge_request_id, unique: true
  end
end
