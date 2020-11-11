# frozen_string_literal: true

class AddIidToDesignManagementDesign < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :design_management_designs, :iid, :integer
  end
end
