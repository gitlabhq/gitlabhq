# frozen_string_literal: true

class RemovePushRulesRegexLimits < Gitlab::Database::Migration[2.1]
  def up
    change_column :push_rules, :force_push_regex, :string, limit: nil
    change_column :push_rules, :delete_branch_regex, :string, limit: nil
    change_column :push_rules, :commit_message_regex, :string, limit: nil
    change_column :push_rules, :commit_message_negative_regex, :string, limit: nil
    change_column :push_rules, :author_email_regex, :string, limit: nil
    change_column :push_rules, :file_name_regex, :string, limit: nil
    change_column :push_rules, :branch_name_regex, :string, limit: nil
  end

  def down
    # No op
  end
end
