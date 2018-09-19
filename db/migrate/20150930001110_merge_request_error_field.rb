class MergeRequestErrorField < ActiveRecord::Migration
  def up
    add_column :merge_requests, :merge_error, :string
  end
end
