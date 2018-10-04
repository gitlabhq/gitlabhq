class MergeRequestDiffFileLimitsToMysql < ActiveRecord::Migration
  DOWNTIME = false

  def up
    return unless Gitlab::Database.mysql?

    change_column :merge_request_diff_files, :diff, :text, limit: 2147483647, default: nil
  end

  def down
  end
end
