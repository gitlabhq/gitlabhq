# frozen_string_literal: true

class AddIterationIdToLists < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :lists, :iteration_id, :bigint
  end
end
