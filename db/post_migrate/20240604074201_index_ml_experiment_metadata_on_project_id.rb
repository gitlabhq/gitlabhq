# frozen_string_literal: true

class IndexMlExperimentMetadataOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_ml_experiment_metadata_on_project_id'

  def up
    add_concurrent_index :ml_experiment_metadata, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ml_experiment_metadata, INDEX_NAME
  end
end
