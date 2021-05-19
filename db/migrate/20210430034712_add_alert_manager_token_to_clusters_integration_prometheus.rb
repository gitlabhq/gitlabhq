# frozen_string_literal: true

class AddAlertManagerTokenToClustersIntegrationPrometheus < ActiveRecord::Migration[6.0]
  def change
    change_table :clusters_integration_prometheus do |t|
      t.text :encrypted_alert_manager_token
      t.text :encrypted_alert_manager_token_iv
    end
  end
end
