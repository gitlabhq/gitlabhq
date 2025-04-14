# frozen_string_literal: true

class CreateAnalyzerNamespaceStatuses < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  ANALYZER_TYPE_INDEX_NAME = 'index_analyzer_namespace_statuses_status'
  TRAVERSAL_IDS_INDEX_NAME = 'index_analyzer_namespace_statuses_traversal_ids'

  def up
    create_table :analyzer_namespace_statuses do |t|
      t.timestamps_with_timezone null: false
      t.bigint :namespace_id, null: false
      t.column :analyzer_type, :smallint, null: false
      t.bigint :success, default: 0, null: false
      t.bigint :failure, default: 0, null: false
      t.bigint :traversal_ids, array: true, default: [], null: false
      t.index :traversal_ids, name: TRAVERSAL_IDS_INDEX_NAME
      t.index [:namespace_id, :analyzer_type], unique: true, name: ANALYZER_TYPE_INDEX_NAME
    end
  end

  def down
    drop_table :analyzer_namespace_statuses
  end
end
