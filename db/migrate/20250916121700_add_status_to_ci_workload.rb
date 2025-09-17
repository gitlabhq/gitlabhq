# frozen_string_literal: true

class AddStatusToCiWorkload < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def change
    add_column :p_ci_workloads, :status, :smallint, default: 0, null: false
  end
end
