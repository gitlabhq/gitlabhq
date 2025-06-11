# frozen_string_literal: true

class AddAllowBypassPlaceholderConfirmationForEnterpriseToNamespaceSettings < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    add_column :namespace_settings, :allow_enterprise_bypass_placeholder_confirmation, :boolean,
      default: false, null: false
  end
end
