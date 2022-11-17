# frozen_string_literal: true

class CreatePackageMetadataLicenses < Gitlab::Database::Migration[2.0]
  def change
    create_table :pm_licenses do |t|
      t.text :spdx_identifier, null: false, limit: 50
      t.index [:spdx_identifier], unique: true, name: 'i_pm_licenses_on_spdx_identifier'
    end
  end
end
