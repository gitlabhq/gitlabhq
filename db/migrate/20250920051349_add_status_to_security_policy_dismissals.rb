# frozen_string_literal: true

class AddStatusToSecurityPolicyDismissals < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def change
    add_column :security_policy_dismissals, :status, :smallint, default: 0, null: false
  end
end
