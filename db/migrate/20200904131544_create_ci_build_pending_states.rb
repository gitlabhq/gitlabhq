# frozen_string_literal: true

class CreateCiBuildPendingStates < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      create_table :ci_build_pending_states do |t|
        t.timestamps_with_timezone
        t.references :build, index: { unique: true }, null: false, foreign_key: { to_table: :ci_builds, on_delete: :cascade }, type: :bigint
        t.integer :state
        t.integer :failure_reason
        t.binary :trace_checksum
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :ci_build_pending_states
    end
  end
end
