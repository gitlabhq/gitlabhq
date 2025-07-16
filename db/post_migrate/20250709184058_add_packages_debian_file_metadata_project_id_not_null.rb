# frozen_string_literal: true

class AddPackagesDebianFileMetadataProjectIdNotNull < Gitlab::Database::Migration[2.3]
  milestone '18.3'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :packages_debian_file_metadata, :project_id
  end

  def down
    remove_not_null_constraint :packages_debian_file_metadata, :project_id
  end
end
