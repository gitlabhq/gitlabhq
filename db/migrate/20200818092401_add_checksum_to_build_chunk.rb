# frozen_string_literal: true

class AddChecksumToBuildChunk < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :ci_build_trace_chunks, :checksum, :binary
  end
end
