# frozen_string_literal: true

class CreateCiBuildTraceMetadata < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      create_table :ci_build_trace_metadata, id: false, if_not_exists: true do |t|
        t.references :build,
          index: false,
          primary_key: true,
          default: nil,
          foreign_key: { to_table: :ci_builds, on_delete: :cascade },
          type: :bigint,
          null: false

        t.bigint :trace_artifact_id
        t.integer :archival_attempts, default: 0, null: false, limit: 2
        t.binary :checksum
        t.binary :remote_checksum

        t.index :trace_artifact_id
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :ci_build_trace_metadata, if_exists: true
    end
  end
end
