# frozen_string_literal: true

class AddBypassExpiryToNamespaceSettings < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def change
    add_column :namespace_settings, :enterprise_bypass_expires_at, :datetime_with_timezone, null: true
  end
end
