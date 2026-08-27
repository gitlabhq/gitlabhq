# frozen_string_literal: true

class DropProjectPushRulesTable < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.4'

  TABLE_NAME = :project_push_rules
  FK_NAME = :fk_9ed8a48c44
  INDEX_NAME = :index_project_push_rules_on_project_id

  def up
    with_lock_retries do
      remove_foreign_key_if_exists TABLE_NAME, :projects,
        column: :project_id, name: FK_NAME, reverse_lock_order: true
    end

    drop_table TABLE_NAME, if_exists: true
  end

  def down
    create_table TABLE_NAME, if_not_exists: true do |t|
      t.timestamps_with_timezone null: false

      t.bigint :project_id, null: false

      t.integer :max_file_size, null: false, default: 0

      t.boolean :member_check, null: false, default: false
      t.boolean :prevent_secrets, null: false, default: false
      t.boolean :commit_committer_name_check, null: false, default: false
      t.boolean :deny_delete_tag
      t.boolean :reject_unsigned_commits
      t.boolean :commit_committer_check
      t.boolean :reject_non_dco_commits

      t.text :commit_message_regex, limit: 511
      t.text :branch_name_regex, limit: 511
      t.text :commit_message_negative_regex, limit: 2047
      t.text :author_email_regex, limit: 511
      t.text :file_name_regex, limit: 511
    end

    add_concurrent_index TABLE_NAME, :project_id, unique: true, name: INDEX_NAME

    add_concurrent_foreign_key TABLE_NAME, :projects,
      column: :project_id, on_delete: :cascade, name: FK_NAME
  end
end
