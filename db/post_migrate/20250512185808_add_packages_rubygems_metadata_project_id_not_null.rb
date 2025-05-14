# frozen_string_literal: true

class AddPackagesRubygemsMetadataProjectIdNotNull < Gitlab::Database::Migration[2.3]
  milestone '18.0'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :packages_rubygems_metadata, :project_id
  end

  def down
    remove_not_null_constraint :packages_rubygems_metadata, :project_id
  end
end
