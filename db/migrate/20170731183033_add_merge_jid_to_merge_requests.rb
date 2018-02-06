class AddMergeJidToMergeRequests < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :merge_requests, :merge_jid, :string
  end
end
