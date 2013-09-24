class AddStateToMergeRequest < ActiveRecord::Migration
  def change
    add_column :merge_requests, :state, :string
  end
end
