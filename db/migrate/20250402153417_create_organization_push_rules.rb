# frozen_string_literal: true

class CreateOrganizationPushRules < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      create_table :organization_push_rules, if_not_exists: true do |t|
        t.timestamps_with_timezone null: false

        t.references :organization, index: { unique: true }, foreign_key: { on_delete: :cascade }, null: false
        t.integer :max_file_size, null: false, default: 0

        t.boolean :member_check, null: false, default: false
        t.boolean :prevent_secrets, null: false, default: false
        t.boolean :commit_committer_name_check, null: false, default: false
        t.boolean :deny_delete_tag
        t.boolean :reject_unsigned_commits
        t.boolean :commit_committer_check
        t.boolean :reject_non_dco_commits

        # rubocop:disable Migration/AddLimitToTextColumns -- limit is added in add_check_constraint
        t.text :commit_message_regex
        t.text :branch_name_regex
        t.text :commit_message_negative_regex
        t.text :author_email_regex
        t.text :file_name_regex
        # rubocop:enable Migration/AddLimitToTextColumns
      end
    end

    add_check_constraint :organization_push_rules, "char_length(author_email_regex) <= 511",
      "author_email_regex_size_constraint"
    add_check_constraint :organization_push_rules, "char_length(branch_name_regex) <= 511",
      "branch_name_regex_size_constraint"
    add_check_constraint :organization_push_rules, "char_length(commit_message_negative_regex) <= 2047",
      "commit_message_negative_regex_size_constraint"
    add_check_constraint :organization_push_rules, "char_length(commit_message_regex) <= 511",
      "commit_message_regex_size_constraint"
    add_check_constraint :organization_push_rules, "char_length(file_name_regex) <= 511",
      "file_name_regex_size_constraint"
  end

  def down
    with_lock_retries do
      drop_table :organization_push_rules, if_exists: true
    end
  end
end
