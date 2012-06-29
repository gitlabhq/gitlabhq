class IncreaseMrTextColumnSize < ActiveRecord::Migration
  def up
    # MYSQL LARGETEXT for merge request
    unless connection.adapter_name == 'PostgreSQL'
      change_column :merge_requests, :st_diffs, :text, :limit => 4294967295
      change_column :merge_requests, :st_commits, :text, :limit => 4294967295
    end
  end

  def down
  end
end
