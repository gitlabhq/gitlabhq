# frozen_string_literal: true

class CreatePackagesPypiFileMetadata < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def change
    create_table :packages_pypi_file_metadata, id: false do |t|
      t.timestamps_with_timezone null: false
      t.bigint :package_file_id, null: false, default: nil, primary_key: true
      t.bigint :project_id, null: false, index: true
      t.text :required_python, null: false, default: '', limit: 255
    end
  end
end
