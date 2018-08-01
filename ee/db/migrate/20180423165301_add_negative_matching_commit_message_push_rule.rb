class AddNegativeMatchingCommitMessagePushRule < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column :push_rules, :commit_message_negative_regex, :string, null: true
  end

  def down
    remove_column :push_rules, :commit_message_negative_regex
  end
end
