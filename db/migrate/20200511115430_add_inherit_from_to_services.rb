# frozen_string_literal: true

class AddInheritFromToServices < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :services, :inherit_from_id, :bigint
  end
end
