# frozen_string_literal: true

class AddStartDateToIssuesTable < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :issues, :start_date, :date
  end
end
