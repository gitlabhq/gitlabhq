# frozen_string_literal: true

class CreatePackageMetadata < Gitlab::Database::Migration[2.0]
  def change
    create_table :pm_packages do |t|
      t.integer :purl_type, null: false, limit: 2
      t.text :name, null: false, limit: 255
      t.index [:purl_type, :name], unique: true, name: 'i_pm_packages_purl_type_and_name'
    end
  end
end
