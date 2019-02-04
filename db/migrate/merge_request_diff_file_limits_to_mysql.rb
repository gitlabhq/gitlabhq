class MergeRequestDiffFileLimitsToMysql < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def up
    return unless Gitlab::Database.mysql?

    change_column :merge_request_diff_files, :diff, :text, limit: 2147483647, default: nil
  end

  def down
  end
end
