# frozen_string_literal: true

class UpdatePolicyDismissalsWithDismissalTypesCommentAndNullableFindingsUuids < Gitlab::Database::Migration[2.3]
  milestone '18.4'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :security_policy_dismissals, :dismissal_types, :smallint, array: true, default: [],
        if_not_exists: true, null: false
      add_column :security_policy_dismissals, :comment, :text, if_not_exists: true, null: true
      change_column_null :security_policy_dismissals, :security_findings_uuids, true
    end

    add_text_limit :security_policy_dismissals, :comment, 255
  end

  def down
    with_lock_retries do
      remove_column :security_policy_dismissals, :dismissal_types, if_exists: true
      remove_column :security_policy_dismissals, :comment, if_exists: true
      change_column_null :security_policy_dismissals, :security_findings_uuids, false
    end
  end
end
