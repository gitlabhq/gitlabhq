# frozen_string_literal: true

class RemoveClustersApplicationsFluentdTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    drop_table :clusters_applications_fluentd
  end

  def down
    create_table :clusters_applications_fluentd do |t|
      t.integer :protocol, null: false, limit: 2
      t.integer :status, null: false
      t.integer :port, null: false
      t.references :cluster, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.string :version, null: false, limit: 255
      t.string :host, null: false, limit: 255
      t.boolean :cilium_log_enabled, default: true, null: false
      t.boolean :waf_log_enabled, default: true, null: false
      t.text :status_reason # rubocop:disable Migration/AddLimitToTextColumns
    end
  end
end
