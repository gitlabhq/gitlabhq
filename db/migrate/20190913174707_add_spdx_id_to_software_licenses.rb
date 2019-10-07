# frozen_string_literal: true

class AddSpdxIdToSoftwareLicenses < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    add_column :software_licenses, :spdx_identifier, :string, limit: 255
  end

  def down
    remove_column :software_licenses, :spdx_identifier
  end
end
