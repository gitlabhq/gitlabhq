# rubocop:disable all
class AddDescriptionToMergeRequest < ActiveRecord::Migration[4.2]
  def change
    add_column :merge_requests, :description, :text, null: true
  end
end
