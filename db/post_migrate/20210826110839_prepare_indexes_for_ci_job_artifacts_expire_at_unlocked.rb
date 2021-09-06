# frozen_string_literal: true

class PrepareIndexesForCiJobArtifactsExpireAtUnlocked < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  TABLE_NAME = 'ci_job_artifacts'
  INDEX_NAME = 'ci_job_artifacts_expire_at_unlocked_idx'

  def up
    prepare_async_index TABLE_NAME, [:expire_at], where: 'locked = 0', name: INDEX_NAME
  end

  def down
    unprepare_async_index_by_name TABLE_NAME, INDEX_NAME
  end
end
