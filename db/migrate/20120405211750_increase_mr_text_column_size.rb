class IncreaseMrTextColumnSize < ActiveRecord::Migration
  def up
    # MYSQL LARGETEXT for merge request
    change_column :merge_requests, :st_diffs, :text, :limit => 4294967295
    change_column :merge_requests, :st_commits, :text, :limit => 4294967295
  end

  def down
  end
end
