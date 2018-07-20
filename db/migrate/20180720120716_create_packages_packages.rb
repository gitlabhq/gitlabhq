class CreatePackagesPackages < ActiveRecord::Migration
  def change
    create_table :packages_packages do |t|
      t.references :project, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.string :name
      t.string :version

      t.timestamps null: false
    end
  end
end
