# frozen_string_literal: true

class AddImageToDesignManagementDesignsVersions < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :design_management_designs_versions, :image_v432x230, :string, limit: 255
  end
end
