# frozen_string_literal: true

class AddIndexToNamespaceSettingsOnDefaultComplianceFrameworkId < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'idx_namespace_settings_on_default_compliance_framework_id'

  def up
    add_concurrent_index :namespace_settings, :default_compliance_framework_id, unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :namespace_settings, :default_compliance_framework_id, name: INDEX_NAME
  end
end
