# frozen_string_literal: true

class CreateProtectedEnvironmentApprovalRules < Gitlab::Database::Migration[1.0]
  def up
    create_table :protected_environment_approval_rules do |t|
      t.references :protected_environment,
                   index: { name: :index_approval_rule_on_protected_environment_id },
                   foreign_key: { to_table: :protected_environments, on_delete: :cascade },
                   null: false

      t.bigint :user_id
      t.bigint :group_id
      t.timestamps_with_timezone null: false
      t.integer :access_level, limit: 2
      t.integer :required_approvals, null: false, limit: 2

      t.index :user_id
      t.index :group_id

      t.check_constraint "((access_level IS NOT NULL) AND (group_id IS NULL) AND (user_id IS NULL)) OR " \
                         "((user_id IS NOT NULL) AND (access_level IS NULL) AND (group_id IS NULL)) OR " \
                         "((group_id IS NOT NULL) AND (user_id IS NULL) AND (access_level IS NULL))"
      t.check_constraint "required_approvals > 0"
    end
  end

  def down
    drop_table :protected_environment_approval_rules
  end
end
