# frozen_string_literal: true

class AddMetadataColumnToSecurityPolicies < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    add_column :security_policies, :metadata, :jsonb, default: {}, null: false
  end
end
