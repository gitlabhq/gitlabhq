# frozen_string_literal: true

class AddFkToAiSettingsOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ai_settings, :organizations,
      column: :organization_id, on_delete: :cascade, validate: true
  end

  def down
    remove_foreign_key_if_exists :ai_settings, :organizations, column: :organization_id
  end
end
