# frozen_string_literal: true .

class CreatePackageTag < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :packages_package_tags do |t|
      t.references :package, index: true, null: false, foreign_key: { to_table: :packages_packages, on_delete: :cascade }, type: :integer
      t.string :name, limit: 255, null: false # rubocop:disable Migration/PreventStrings
    end
  end
end
