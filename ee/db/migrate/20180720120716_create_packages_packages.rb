# frozen_string_literal: true
class CreatePackagesPackages < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :packages_packages do |t|
      t.references :project, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.string :name, null: false
      t.string :version

      t.timestamps_with_timezone null: false
    end
  end
end
