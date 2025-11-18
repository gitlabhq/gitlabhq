# frozen_string_literal: true

class AddLicensesToPolicyDismissal < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def change
    add_column :security_policy_dismissals, :licenses, :jsonb, default: {}, null: false
  end
end
