# frozen_string_literal: true

class AddPartialIndexForCiPipelineArtifactsUnlockedWithExpireAt < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  TABLE_NAME = 'ci_pipeline_artifacts'
  INDEX_NAME = 'ci_pipeline_artifacts_on_expire_at_for_removal'
  CONDITIONS = 'locked = 0 AND expire_at IS NOT NULL'

  def up
    add_concurrent_index TABLE_NAME, [:expire_at], where: CONDITIONS, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
