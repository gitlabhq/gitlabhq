# frozen_string_literal: true

class CreatePypiPackageMetadata < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :packages_pypi_metadata, id: false do |t|
      t.references :package, primary_key: true, index: false, default: nil, foreign_key: { to_table: :packages_packages, on_delete: :cascade }, type: :bigint
      t.string "required_python", null: false, limit: 50 # rubocop:disable Migration/PreventStrings
    end
  end
end
