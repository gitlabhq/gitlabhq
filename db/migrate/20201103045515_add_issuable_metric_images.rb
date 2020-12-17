# frozen_string_literal: true

class AddIssuableMetricImages < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:issuable_metric_images)
      with_lock_retries do
        create_table :issuable_metric_images do |t|
          t.references :issue, null: false, index: true, foreign_key: { on_delete: :cascade }
          t.timestamps_with_timezone
          t.integer :file_store, limit: 2
          t.text :file, null: false
          t.text :url
        end
      end
    end

    add_text_limit(:issuable_metric_images, :url, 255)
    add_text_limit(:issuable_metric_images, :file, 255)
  end

  def down
    with_lock_retries do
      drop_table :issuable_metric_images
    end
  end
end
