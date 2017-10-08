class AddMergeJidToMergeRequests < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    add_column :merge_requests, :merge_jid, :string
  end
end
