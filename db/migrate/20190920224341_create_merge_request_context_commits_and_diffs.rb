# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateMergeRequestContextCommitsAndDiffs < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  # rubocop:disable Migration/AddLimitToTextColumns
  def change
    create_table :merge_request_context_commits do |t|
      t.references :merge_request, foreign_key: { on_delete: :cascade }
      t.datetime_with_timezone :authored_date
      t.datetime_with_timezone :committed_date
      t.binary :sha, null: false
      t.integer :relative_order, null: false
      t.text :author_name
      t.text :author_email
      t.text :committer_name
      t.text :committer_email
      t.text :message
      t.index [:merge_request_id, :sha], unique: true, name: 'index_mr_context_commits_on_merge_request_id_and_sha'
    end

    create_table :merge_request_context_commit_diff_files, id: false do |t|
      t.references :merge_request_context_commit, foreign_key: { on_delete: :cascade }, index: { name: "idx_mr_cc_diff_files_on_mr_cc_id" }
      t.binary :sha, null: false
      t.integer :relative_order, null: false
      t.string :a_mode, null: false, limit: 255
      t.string :b_mode, null: false, limit: 255
      t.boolean :new_file, null: false
      t.boolean :renamed_file, null: false
      t.boolean :deleted_file, null: false
      t.boolean :too_large, null: false
      t.boolean :binary
      t.text :new_path, null: false
      t.text :old_path, null: false
      t.text :diff
      t.index [:merge_request_context_commit_id, :sha], name: 'idx_mr_cc_diff_files_on_mr_cc_id_and_sha'
    end
  end
  # rubocop:enable Migration/AddLimitToTextColumns
  # rubocop:enable Migration/PreventStrings
end
