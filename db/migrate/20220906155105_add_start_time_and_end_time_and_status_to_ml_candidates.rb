# frozen_string_literal: true

class AddStartTimeAndEndTimeAndStatusToMlCandidates < Gitlab::Database::Migration[2.0]
  def change
    add_column :ml_candidates, :start_time, :bigint
    add_column :ml_candidates, :end_time, :bigint
    add_column :ml_candidates, :status, :smallint, default: 0, null: false
  end
end
