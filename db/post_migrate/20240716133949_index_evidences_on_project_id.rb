# frozen_string_literal: true

class IndexEvidencesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  disable_ddl_transaction!

  INDEX_NAME = 'index_evidences_on_project_id'

  def up
    add_concurrent_index :evidences, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :evidences, INDEX_NAME
  end
end
