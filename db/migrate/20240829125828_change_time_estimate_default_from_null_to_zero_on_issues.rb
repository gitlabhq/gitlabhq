# frozen_string_literal: true

class ChangeTimeEstimateDefaultFromNullToZeroOnIssues < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  enable_lock_retries!

  TABLE_NAME = :issues
  COLUMN_NAME = :time_estimate

  def up
    change_column_default(TABLE_NAME, COLUMN_NAME, from: nil, to: 0)
  end

  def down
    remove_column_default(TABLE_NAME, COLUMN_NAME)
  end
end
