# frozen_string_literal: true

class PrepareToDropIndexPCiBuildsTriggerRequestId < Gitlab::Database::Migration[2.2]
  milestone '18.0'
  disable_ddl_transaction!

  TABLE = :p_ci_builds
  COLUMN = :trigger_request_id
  INDEX_NAME = :tmp_p_ci_builds_trigger_request_id_idx

  def up
    prepare_async_index_removal(TABLE, COLUMN, name: INDEX_NAME)
  end

  def down
    unprepare_async_index(TABLE, COLUMN, name: INDEX_NAME)
  end
end
