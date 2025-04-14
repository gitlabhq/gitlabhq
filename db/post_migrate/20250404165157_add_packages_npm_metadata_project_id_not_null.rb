# frozen_string_literal: true

class AddPackagesNpmMetadataProjectIdNotNull < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :packages_npm_metadata, :project_id, validate: false
  end

  def down
    remove_not_null_constraint :packages_npm_metadata, :project_id
  end
end
