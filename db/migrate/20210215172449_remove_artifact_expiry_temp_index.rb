# frozen_string_literal: true

class RemoveArtifactExpiryTempIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'expired_artifacts_temp_index'
  INDEX_CONDITION = "expire_at IS NULL AND date(created_at AT TIME ZONE 'UTC') < '2020-06-22'::date"

  def up
    remove_concurrent_index_by_name :ci_job_artifacts, INDEX_NAME
  end

  def down
    add_concurrent_index(:ci_job_artifacts, %i(id created_at), where: INDEX_CONDITION, name: INDEX_NAME)
  end
end
