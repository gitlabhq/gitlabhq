class RemoveMRdiffFields < ActiveRecord::Migration
  def up
    remove_column :merge_requests, :st_commits
    remove_column :merge_requests, :st_diffs
  end

  def down
    add_column :merge_requests, :st_commits, :text, null: true, limit: 2147483647
    add_column :merge_requests, :st_diffs, :text, null: true, limit: 2147483647

    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      execute "UPDATE merge_requests mr
              SET (st_commits, st_diffs) = (md.st_commits, md.st_diffs)
              FROM merge_request_diffs md
              WHERE md.merge_request_id = mr.id"
    else
      execute "UPDATE merge_requests mr, merge_request_diffs md SET mr.st_commits = md.st_commits WHERE md.merge_request_id = mr.id"
      execute "UPDATE merge_requests mr, merge_request_diffs md SET mr.st_diffs = md.st_diffs WHERE md.merge_request_id = mr.id"
    end
  end
end
