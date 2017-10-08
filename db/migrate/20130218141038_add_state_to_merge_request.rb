# rubocop:disable all
class AddStateToMergeRequest < ActiveRecord::Migration[4.2]
  def change
    add_column :merge_requests, :state, :string
  end
end
