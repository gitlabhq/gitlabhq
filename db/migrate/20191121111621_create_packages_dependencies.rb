# frozen_string_literal: true

class CreatePackagesDependencies < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :packages_dependencies do |t|
      t.string :name, null: false, limit: 255
      t.string :version_pattern, null: false, limit: 255
    end

    add_index :packages_dependencies, [:name, :version_pattern], unique: true
  end
end
