# frozen_string_literal: true

class AddCheckConstraintToConanFileMetadata < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_conan_file_metadata_ref_null_for_recipe_files'
  RECIPE_FILE = 1

  def up
    add_check_constraint :packages_conan_file_metadata,
      "NOT (conan_file_type = #{RECIPE_FILE} AND package_reference_id IS NOT NULL)", CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :packages_conan_file_metadata, CONSTRAINT_NAME
  end
end
