# rubocop:disable all
class AddLockedAtToMergeRequest < ActiveRecord::Migration[4.2]
  def change
    add_column :merge_requests, :locked_at, :datetime
  end
end
