# frozen_string_literal: true

class AddPackagesDebianFileMetadataProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def up
    install_sharding_key_assignment_trigger(
      table: :packages_debian_file_metadata,
      sharding_key: :project_id,
      parent_table: :packages_package_files,
      parent_sharding_key: :project_id,
      foreign_key: :package_file_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :packages_debian_file_metadata,
      sharding_key: :project_id,
      parent_table: :packages_package_files,
      parent_sharding_key: :project_id,
      foreign_key: :package_file_id
    )
  end
end
