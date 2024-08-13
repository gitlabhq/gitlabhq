# frozen_string_literal: true

class AddContentColumnToSecurityPolicies < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    add_column :security_policies, :content, :jsonb, default: {}, null: false
  end
end
