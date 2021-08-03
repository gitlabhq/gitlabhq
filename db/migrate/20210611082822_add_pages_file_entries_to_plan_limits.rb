# frozen_string_literal: true

class AddPagesFileEntriesToPlanLimits < ActiveRecord::Migration[6.1]
  def change
    add_column(:plan_limits, :pages_file_entries, :integer, default: 200_000, null: false)
  end
end
