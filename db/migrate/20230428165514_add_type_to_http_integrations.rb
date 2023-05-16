# frozen_string_literal: true

class AddTypeToHttpIntegrations < Gitlab::Database::Migration[2.1]
  def change
    add_column :alert_management_http_integrations, :type_identifier, :integer, default: 0, null: false, limit: 2
  end
end
