# frozen_string_literal: true

class AddJobTokenPoliciesEnabledColumnToNamespaceSettings < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :namespace_settings, :job_token_policies_enabled, :boolean, default: false, null: false
  end
end
