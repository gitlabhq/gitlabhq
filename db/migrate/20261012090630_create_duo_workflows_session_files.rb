# frozen_string_literal: true

class CreateDuoWorkflowsSessionFiles < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  def change
    create_table :duo_workflows_session_files do |t|
      t.timestamps_with_timezone null: false
      # Nullified rather than cascaded on session delete, so a cleanup worker can delete the row and the
      # associated file when workflow_id is null.
      t.bigint :workflow_id, null: true, index: true
      t.bigint :project_id, null: true, index: true
      t.bigint :namespace_id, null: true, index: true
      t.bigint :size, null: false
      t.integer :file_store, limit: 2, default: 1, null: false
      t.text :file, null: false, limit: 255
      t.text :content_type, null: false, limit: 255
      t.check_constraint 'num_nonnulls(namespace_id, project_id) = 1',
        name: 'check_duo_workflows_session_files_sharding_key'
    end
  end
end
