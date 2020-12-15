# frozen_string_literal: true

class AddTraceBytesizeToCiBuildPendingStates < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :ci_build_pending_states, :trace_bytesize, :bigint
  end
end
