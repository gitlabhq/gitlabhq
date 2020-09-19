# frozen_string_literal: true

class AddIndexExpireAtToPipelineArtifacts < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_ci_pipeline_artifacts_on_expire_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_pipeline_artifacts, :expire_at, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name(:ci_pipeline_artifacts, INDEX_NAME)
  end
end
