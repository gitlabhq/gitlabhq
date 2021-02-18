# frozen_string_literal: true

class CreatePackagesDebianPublications < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :packages_debian_publications do |t|
      t.references :package,
        index: { unique: true },
        null: false,
        foreign_key: { to_table: :packages_packages, on_delete: :cascade }
      t.references :distribution,
        null: false,
        foreign_key: { to_table: :packages_debian_project_distributions, on_delete: :cascade }
    end
  end
end
