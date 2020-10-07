# frozen_string_literal: true

class AddLockVersionToCiBuildTraceChunk < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :ci_build_trace_chunks, :lock_version, :integer, default: 0, null: false
  end
end
