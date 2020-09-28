# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddIndicesToApprovalProjectRules < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  RULE_TYPE_INDEX_NAME = 'index_approval_project_rules_on_id_with_regular_type'
  RULE_ID_INDEX_NAME = 'index_approval_project_rules_users_on_approval_project_rule_id'

  def up
    add_concurrent_index :approval_project_rules, :id, where: 'rule_type = 0', name: RULE_TYPE_INDEX_NAME
    add_concurrent_index :approval_project_rules_users, :approval_project_rule_id, name: RULE_ID_INDEX_NAME
  end

  def down
    remove_concurrent_index :approval_project_rules, :id, where: 'rule_type = 0', name: RULE_TYPE_INDEX_NAME
    remove_concurrent_index :approval_project_rules_users, :approval_project_rule_id, name: RULE_ID_INDEX_NAME
  end
end
