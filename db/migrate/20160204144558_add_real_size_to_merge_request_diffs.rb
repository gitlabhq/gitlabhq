class AddRealSizeToMergeRequestDiffs < ActiveRecord::Migration[4.2]
  def change
    add_column :merge_request_diffs, :real_size, :string
  end
end
