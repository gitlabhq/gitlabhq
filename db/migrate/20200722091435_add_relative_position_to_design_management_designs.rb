# frozen_string_literal: true

class AddRelativePositionToDesignManagementDesigns < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :design_management_designs, :relative_position, :integer
  end
end
