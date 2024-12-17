# frozen_string_literal: true

class RemovePushTablesForcePushDeleteBranchRegex < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  disable_ddl_transaction!

  def up
    remove_column :push_rules, :force_push_regex, if_exists: true
    remove_column :push_rules, :delete_branch_regex, if_exists: true
  end

  def down
    add_column :push_rules, :force_push_regex, :string, if_not_exists: true
    add_column :push_rules, :delete_branch_regex, :string, if_not_exists: true

    # Re-add constraints
    add_check_constraint(:push_rules, 'char_length(force_push_regex) <= 511', 'force_push_regex_size_constraint')
    add_check_constraint(:push_rules, 'char_length(delete_branch_regex) <= 511', 'delete_branch_regex_size_constraint')
  end
end
