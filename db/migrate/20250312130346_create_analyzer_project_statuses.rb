# frozen_string_literal: true

class CreateAnalyzerProjectStatuses < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  ANALYZER_TYPE_INDEX_NAME = 'index_analyzer_project_statuses_status'
  TRAVERSAL_IDS_INDEX_NAME = 'index_analyzer_project_statuses_traversal_ids'

  def up
    create_table :analyzer_project_statuses do |t|
      t.timestamps_with_timezone null: false
      t.bigint :project_id, null: false
      t.column :analyzer_type, :smallint, null: false
      t.column :status, :smallint, null: false
      t.datetime_with_timezone :last_call, null: false
      t.bigint :traversal_ids, array: true, default: [], null: false
      t.index :traversal_ids, name: TRAVERSAL_IDS_INDEX_NAME
      t.index [:project_id, :analyzer_type], unique: true, name: ANALYZER_TYPE_INDEX_NAME
    end
  end

  def down
    drop_table :analyzer_project_statuses
  end
end
