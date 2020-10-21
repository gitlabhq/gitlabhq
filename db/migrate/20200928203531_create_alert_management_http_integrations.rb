# frozen_string_literal: true

class CreateAlertManagementHttpIntegrations < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  UNIQUE_INDEX = 'index_http_integrations_on_active_and_project_and_endpoint'

  disable_ddl_transaction!

  def up
    create_table :alert_management_http_integrations, if_not_exists: true do |t|
      t.timestamps_with_timezone
      t.bigint :project_id, index: true, null: false
      t.boolean :active, null: false, default: false
      t.text :encrypted_token, null: false
      t.text :encrypted_token_iv, null: false
      t.text :endpoint_identifier, null: false
      t.text :name, null: false
    end

    add_text_limit :alert_management_http_integrations, :encrypted_token, 255
    add_text_limit :alert_management_http_integrations, :encrypted_token_iv, 255
    add_text_limit :alert_management_http_integrations, :endpoint_identifier, 255
    add_text_limit :alert_management_http_integrations, :name, 255

    add_index :alert_management_http_integrations,
              [:active, :project_id, :endpoint_identifier],
              unique: true,
              name: UNIQUE_INDEX,
              where: 'active'
  end

  def down
    drop_table :alert_management_http_integrations
  end
end
