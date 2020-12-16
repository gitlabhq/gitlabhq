# frozen_string_literal: true

class AddCustomMappingColumnsToHttpIntegrations < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :alert_management_http_integrations, :payload_example, :jsonb, null: false, default: {}
    add_column :alert_management_http_integrations, :payload_attribute_mapping, :jsonb, null: false, default: {}
  end
end
