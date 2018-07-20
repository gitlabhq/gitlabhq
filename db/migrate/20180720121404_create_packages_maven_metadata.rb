class CreatePackagesMavenMetadata < ActiveRecord::Migration
  def change
    create_table :packages_maven_metadata do |t|
      t.references :package, index: true, foreign_key: true, null: false
      t.string :app_group, null: false
      t.string :app_name, null: false
      t.string :app_version, null: false

      t.timestamps null: false
    end
  end
end
