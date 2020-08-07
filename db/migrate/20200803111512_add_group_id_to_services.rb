# frozen_string_literal: true

class AddGroupIdToServices < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :services, :group_id, :bigint
  end
end
