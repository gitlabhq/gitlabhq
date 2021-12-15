# frozen_string_literal: true

class UpdateTimelogsSpentAtDefault < Gitlab::Database::Migration[1.0]
  def change
    change_column_default(:timelogs, :spent_at, from: nil, to: -> { 'NOW()' })
  end
end
