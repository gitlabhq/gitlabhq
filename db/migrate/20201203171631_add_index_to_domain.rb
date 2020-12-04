# frozen_string_literal: true

class AddIndexToDomain < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false
  INDEX_NAME = 'index_alert_management_alerts_on_domain'

  disable_ddl_transaction!

  def up
    add_concurrent_index :alert_management_alerts, :domain, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :alert_management_alerts, :domain, name: INDEX_NAME
  end
end
