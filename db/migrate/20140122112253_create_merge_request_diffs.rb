class CreateMergeRequestDiffs < ActiveRecord::Migration
  def change
    create_table :merge_request_diffs do |t|
      t.string :state, null: false, default: 'collected'
      t.text :st_commits, null: true, limit: 2147483647
      t.text :st_diffs, null: true, limit: 2147483647
      t.integer :merge_request_id, null: false

      t.timestamps
    end
  end
end
