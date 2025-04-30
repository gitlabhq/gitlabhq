# frozen_string_literal: true

class ChangeNamespaceSettingsDefault < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  TABLE_NAME = :namespace_settings
  COLUMN_NAME = :require_dpop_for_manage_api_endpoints

  def change
    change_column_default(TABLE_NAME, COLUMN_NAME, from: true, to: false)
  end
end
