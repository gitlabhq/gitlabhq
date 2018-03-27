class AddBinaryToMergeRequestDiffFiles < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :merge_request_diff_files, :binary, :boolean
  end
end
