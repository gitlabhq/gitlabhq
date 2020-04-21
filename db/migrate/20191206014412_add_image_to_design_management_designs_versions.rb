# frozen_string_literal: true

class AddImageToDesignManagementDesignsVersions < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    add_column :design_management_designs_versions, :image_v432x230, :string, limit: 255
  end
  # rubocop:enable Migration/PreventStrings
end
