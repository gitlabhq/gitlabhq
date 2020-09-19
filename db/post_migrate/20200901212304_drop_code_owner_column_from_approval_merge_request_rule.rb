# frozen_string_literal: true

class DropCodeOwnerColumnFromApprovalMergeRequestRule < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_column :approval_merge_request_rules, :code_owner
    end
  end

  def down
    unless column_exists?(:approval_merge_request_rules, :code_owner)
      with_lock_retries do
        add_column :approval_merge_request_rules, :code_owner, :boolean, default: false, null: false
      end
    end

    add_concurrent_index(
      :approval_merge_request_rules,
      [:merge_request_id, :code_owner, :name],
      unique: true,
      where: "code_owner = true AND section IS NULL",
      name: "approval_rule_name_index_for_code_owners"
    )

    add_concurrent_index(
      :approval_merge_request_rules,
      [:merge_request_id, :code_owner],
      name: "index_approval_merge_request_rules_1"
    )
  end
end
