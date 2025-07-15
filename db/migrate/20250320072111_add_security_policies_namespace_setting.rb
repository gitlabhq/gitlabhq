# frozen_string_literal: true

class AddSecurityPoliciesNamespaceSetting < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :namespace_settings, :security_policies, :jsonb, default: {}, null: false
  end
end
