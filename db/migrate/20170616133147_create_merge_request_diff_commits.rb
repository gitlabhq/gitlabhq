class CreateMergeRequestDiffCommits < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :merge_request_diff_commits, id: false do |t|
      t.datetime_with_timezone :authored_date
      t.datetime_with_timezone :committed_date
      t.belongs_to :merge_request_diff, null: false, foreign_key: { on_delete: :cascade }
      t.integer :relative_order, null: false
      t.binary :sha, null: false, limit: 20
      t.text :author_name
      t.text :author_email
      t.text :committer_name
      t.text :committer_email
      t.text :message

      t.index [:merge_request_diff_id, :relative_order], name: 'index_merge_request_diff_commits_on_mr_diff_id_and_order', unique: true
    end
  end
end
