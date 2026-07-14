# frozen_string_literal: true

class AddIndexToAiSettingsOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  disable_ddl_transaction!

  INDEX_NAME = :index_ai_settings_on_organization_id

  def up
    add_concurrent_index :ai_settings, :organization_id, unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ai_settings, INDEX_NAME
  end
end
