# frozen_string_literal: true

class AddPackagesConanMetadataProjectIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.10'

  def up
    add_not_null_constraint :packages_conan_metadata, :project_id
  end

  def down
    remove_not_null_constraint :packages_conan_metadata, :project_id
  end
end
