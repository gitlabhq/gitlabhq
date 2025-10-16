# frozen_string_literal: true

class CreateProjectPushRules < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    create_table :project_push_rules, if_not_exists: true do |t| # rubocop:disable Migration/EnsureFactoryForTable -- factory will use existing PushRule factory
      t.timestamps_with_timezone null: false

      t.bigint :project_id, null: false
      t.index :project_id, unique: true

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
  end

  def down
    drop_table :project_push_rules, if_exists: true
  end
end
