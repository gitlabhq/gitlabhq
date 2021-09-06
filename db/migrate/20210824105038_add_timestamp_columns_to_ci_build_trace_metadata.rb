# frozen_string_literal: true

class AddTimestampColumnsToCiBuildTraceMetadata < Gitlab::Database::Migration[1.0]
  def change
    add_column :ci_build_trace_metadata, :last_archival_attempt_at, :datetime_with_timezone
    add_column :ci_build_trace_metadata, :archived_at, :datetime_with_timezone
  end
end
