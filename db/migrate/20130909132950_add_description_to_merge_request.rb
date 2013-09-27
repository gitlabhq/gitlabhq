class AddDescriptionToMergeRequest < ActiveRecord::Migration
  def change
    add_column :merge_requests, :description, :text, null: true
  end
end
