# frozen_string_literal: true

class CreateAlertManagementAlertMetricImages < Gitlab::Database::Migration[1.0]
  def up
    create_table :alert_management_alert_metric_images do |t|
      t.references :alert, null: false, index: true, foreign_key: { to_table: :alert_management_alerts, on_delete: :cascade }
      t.timestamps_with_timezone
      t.integer :file_store, limit: 2
      t.text :file, limit: 255, null: false
      t.text :url, limit: 255
      t.text :url_text, limit: 128
    end
  end

  def down
    drop_table :alert_management_alert_metric_images, if_exists: true
  end
end
