class DropMergeParamsColumn < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    remove_column(:merge_requests, :merge_params, :text)
  end
end
