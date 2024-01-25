# frozen_string_literal: true

class AddZoektRepositoryModel < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  STATE_INDEX_NAME = 'index_zoekt_repositories_on_state'
  PROJECT_ID_INDEX_NAME = 'index_zoekt_repositories_on_project_id'
  ZOEKT_INDEX_ID_AND_PROJECT_ID_INDEX_NAME = 'u_zoekt_repositories_zoekt_index_id_and_project_id'
  CONSTRAINT_NAME = 'c_zoekt_repositories_on_project_id_and_project_identifier'
  CONSTRAINT_QUERY = <<~SQL
    project_id IS NULL OR project_identifier = project_id
  SQL

  def change
    create_table :zoekt_repositories do |t|
      t.bigint :zoekt_index_id, null: false
      t.bigint :project_id, null: true
      t.bigint :project_identifier, null: false
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :indexed_at
      t.integer :state, null: false, default: 0, limit: 2
      t.index :state, name: STATE_INDEX_NAME, using: :btree
      t.index :project_id, name: PROJECT_ID_INDEX_NAME, using: :btree
      t.index [:zoekt_index_id, :project_id],
        name: ZOEKT_INDEX_ID_AND_PROJECT_ID_INDEX_NAME, unique: true, using: :btree
      t.check_constraint CONSTRAINT_QUERY, name: CONSTRAINT_NAME
    end
  end
end
