# frozen_string_literal: true

class AddContainerExpirationPoliciesEnableHistoricEntriesToApplicationSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:application_settings, # rubocop:disable Migration/AddColumnWithDefault
                            :container_expiration_policies_enable_historic_entries,
                            :boolean,
                            default: false,
                            allow_null: false)
  end

  def down
    remove_column(:application_settings,
                  :container_expiration_policies_enable_historic_entries)
  end
end
