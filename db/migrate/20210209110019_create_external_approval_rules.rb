# frozen_string_literal: true

class CreateExternalApprovalRules < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    create_table_with_constraints :external_approval_rules, if_not_exists: true do |t|
      t.references :project, foreign_key: { on_delete: :cascade }, null: false, index: false
      t.timestamps_with_timezone
      t.text :external_url, null: false
      t.text_limit :external_url, 255
      t.text :name, null: false
      t.text_limit :name, 255

      t.index([:project_id, :name],
              unique: true,
              name: 'idx_on_external_approval_rules_project_id_name')
      t.index([:project_id, :external_url],
              unique: true,
              name: 'idx_on_external_approval_rules_project_id_external_url')
    end

    create_table :external_approval_rules_protected_branches do |t|
      t.bigint :external_approval_rule_id, null: false, index: { name: 'idx_eaprpb_external_approval_rule_id' }
      t.bigint :protected_branch_id, null: false
      t.index([:protected_branch_id, :external_approval_rule_id],
              unique: true,
              name: 'idx_protected_branch_id_external_approval_rule_id')
    end
  end

  def down
    with_lock_retries do
      drop_table :external_approval_rules_protected_branches, force: :cascade, if_exists: true
    end

    with_lock_retries do
      drop_table :external_approval_rules, force: :cascade, if_exists: true
    end
  end
end
