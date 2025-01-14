# frozen_string_literal: true

class CreatePCiBuildTraceMetadata < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    create_table(:p_ci_build_trace_metadata, primary_key: [:build_id, :partition_id],
      options: 'PARTITION BY LIST (partition_id)', if_not_exists: true) do |t|
      t.bigint :build_id, null: false
      t.bigint :partition_id, null: false
      t.bigint :trace_artifact_id
      t.datetime_with_timezone :last_archival_attempt_at
      t.datetime_with_timezone :archived_at
      t.integer :archival_attempts, default: 0, null: false, limit: 2
      t.binary :checksum
      t.binary :remote_checksum

      t.index :trace_artifact_id
    end
  end
end
