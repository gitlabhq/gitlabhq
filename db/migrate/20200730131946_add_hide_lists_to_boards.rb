# frozen_string_literal: true

class AddHideListsToBoards < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :boards, :hide_backlog_list, :boolean, default: false, null: false
    add_column :boards, :hide_closed_list, :boolean, default: false, null: false
  end
end
