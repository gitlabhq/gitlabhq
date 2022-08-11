# frozen_string_literal: true

class AddTimestampsToProjectStatistics < Gitlab::Database::Migration[2.0]
  def change
    add_timestamps_with_timezone(:project_statistics, null: false, default: -> { 'NOW()' })
  end
end
