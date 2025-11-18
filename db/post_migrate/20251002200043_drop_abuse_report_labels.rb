# frozen_string_literal: true

class DropAbuseReportLabels < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.5'

  def up
    drop_table :abuse_report_labels, if_exists: true
  end

  def down
    with_lock_retries do
      create_table :abuse_report_labels do |t|
        t.timestamps_with_timezone null: false
        t.integer :cached_markdown_version
        t.text :title, limit: 255, index: { unique: true }, null: false
        t.text :color, limit: 7
        t.text :description, limit: 500
        t.text :description_html, limit: 1000
        t.bigint :organization_id
      end
    end

    add_concurrent_index :abuse_report_labels, :organization_id, name: 'index_abuse_report_labels_on_organization_id'
    add_concurrent_index :abuse_report_labels, :description, name: 'index_abuse_report_labels_on_description_trigram',
      using: :gin, opclass: :gin_trgm_ops
    add_concurrent_index :abuse_report_labels, :title, name: 'index_abuse_report_labels_on_title_trigram', using: :gin,
      opclass: :gin_trgm_ops
    add_concurrent_foreign_key :abuse_report_labels, :organizations, column: :organization_id
  end
end
