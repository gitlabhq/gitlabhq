class AddRealSizeToMergeRequestDiffs < ActiveRecord::Migration
  def change
    add_column :merge_request_diffs, :real_size, :string
  end
end
