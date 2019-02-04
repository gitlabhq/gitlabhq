class MergeRequestErrorField < ActiveRecord::Migration[4.2]
  def up
    add_column :merge_requests, :merge_error, :string
  end
end
