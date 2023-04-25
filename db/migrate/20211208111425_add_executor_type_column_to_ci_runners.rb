# frozen_string_literal: true

class AddExecutorTypeColumnToCiRunners < Gitlab::Database::Migration[1.0]
  def change
    add_column :ci_runners, :executor_type, :smallint, null: true
  end
end
