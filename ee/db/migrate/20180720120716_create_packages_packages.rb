# frozen_string_literal: true
class CreatePackagesPackages < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    create_table :packages_packages, id: :bigserial do |t|
      t.timestamps_with_timezone null: false
      t.references :project, index: true, foreign_key: { on_delete: :cascade }, null: false

      t.string :name, null: false
      t.string :version
    end
  end
end
