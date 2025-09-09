# frozen_string_literal: true

class AddMergeRequestForeignKeyToSecurityPolicyDismissals < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  def up
    add_concurrent_foreign_key :security_policy_dismissals, :merge_requests,
      column: :merge_request_id,
      on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :security_policy_dismissals, column: :merge_request_id
  end
end
