# frozen_string_literal: true

class AddConfigurationLinkToScanProfileTriggers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.3'

  INDEX_NAME = 'index_scan_profile_triggers_on_configuration_id'

  def up
    with_lock_retries do
      add_column :security_scan_profile_triggers, :security_scan_profile_configuration_id, :bigint,
        if_not_exists: true
    end

    add_concurrent_index :security_scan_profile_triggers,
      :security_scan_profile_configuration_id, name: INDEX_NAME

    add_concurrent_foreign_key :security_scan_profile_triggers,
      :security_scan_profile_configurations,
      column: :security_scan_profile_configuration_id,
      on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :security_scan_profile_triggers,
        column: :security_scan_profile_configuration_id
    end

    # Dropping the column also drops its index.
    remove_column :security_scan_profile_triggers, :security_scan_profile_configuration_id, if_exists: true
  end
end
