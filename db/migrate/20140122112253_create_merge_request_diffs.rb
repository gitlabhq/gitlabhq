class CreateMergeRequestDiffs < ActiveRecord::Migration
  def up
    create_table :merge_request_diffs do |t|
      t.string :state, null: false, default: 'collected'
      t.text :st_commits, null: true
      t.text :st_diffs, null: true
      t.integer :merge_request_id, null: false

      t.timestamps
    end

    if ActiveRecord::Base.configurations[Rails.env]['adapter'] =~ /^mysql/
      change_column :merge_request_diffs, :st_commits, :text, limit: 2147483647
      change_column :merge_request_diffs, :st_diffs, :text, limit: 2147483647
    end
  end

  def down
    drop_table :merge_request_diffs
  end
end
