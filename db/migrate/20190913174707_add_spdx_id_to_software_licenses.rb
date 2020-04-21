# frozen_string_literal: true

class AddSpdxIdToSoftwareLicenses < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def up
    add_column :software_licenses, :spdx_identifier, :string, limit: 255
  end
  # rubocop:enable Migration/PreventStrings

  def down
    remove_column :software_licenses, :spdx_identifier
  end
end
