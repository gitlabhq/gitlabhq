# frozen_string_literal: true

class CreatePackagesRubygemsSpecFiles < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  PROJECT_ID_AND_FILE_NAME_INDEX_NAME = 'index_packages_rubygems_spec_files_on_project_id_and_file_name'
  PROJECT_ID_AND_STATUS_INDEX_NAME = 'index_packages_rubygems_spec_files_on_project_id_and_status'
  # Name must be at most 63 bytes (see Gitlab::Database::MAX_INDEX_NAME_LENGTH)
  OBJECT_STORAGE_KEY_AND_PROJECT_ID_INDEX_NAME =
    'i_pkgs_rubygems_spec_files_on_obj_stor_key_and_project_id'

  def up
    create_table :packages_rubygems_spec_files do |t|
      t.timestamps_with_timezone

      t.bigint :project_id, null: false
      t.integer :size, null: false
      t.integer :file_store, default: 1
      t.integer :status, default: 0, null: false, limit: 2
      t.text :file_name, null: false, limit: 255
      t.text :file, null: false, limit: 255
      t.text :object_storage_key, null: false, limit: 255

      t.index %i[project_id file_name], name: PROJECT_ID_AND_FILE_NAME_INDEX_NAME, unique: true
      t.index %i[project_id status], name: PROJECT_ID_AND_STATUS_INDEX_NAME
      t.index %i[object_storage_key project_id], name: OBJECT_STORAGE_KEY_AND_PROJECT_ID_INDEX_NAME, unique: true
    end
  end

  def down
    drop_table :packages_rubygems_spec_files
  end
end
