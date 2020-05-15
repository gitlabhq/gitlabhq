# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddRuleTypeToApprovalMergeRequestApprovalRules < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:approval_merge_request_rules, :rule_type, :integer, limit: 2, default: 1) # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column(:approval_merge_request_rules, :rule_type)
  end
end
