class CreatePackagesPackages < ActiveRecord::Migration
  def change
    create_table :packages_packages do |t|
      t.references :project, index: true, foreign_key: true, null: false
      t.string :name
      t.string :version

      t.timestamps null: false
    end
  end
end
