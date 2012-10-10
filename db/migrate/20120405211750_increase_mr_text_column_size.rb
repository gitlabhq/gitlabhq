class IncreaseMrTextColumnSize < ActiveRecord::Migration
  def up
    case ActiveRecord::Base.connection.adapter_name
    when 'PostgreSQL'
      # nothing to do
    else
      # MYSQL LARGETEXT for merge request
      change_column :merge_requests, :st_diffs, :text, :limit => 4294967295
      change_column :merge_requests, :st_commits, :text, :limit => 4294967295
    end
  end

  def down
  end
end
