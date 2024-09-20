# frozen_string_literal: true

class CreateMergeRequestMergeSchedulesShardingKeyFk < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :merge_request_merge_schedules, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :merge_request_merge_schedules, column: :project_id
    end
  end
end
