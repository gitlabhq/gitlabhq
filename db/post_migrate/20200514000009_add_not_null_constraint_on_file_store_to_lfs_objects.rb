# frozen_string_literal: true

class AddNotNullConstraintOnFileStoreToLfsObjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_not_null_constraint(:lfs_objects, :file_store, validate: false)
  end

  def down
    remove_not_null_constraint(:lfs_objects, :file_store)
  end
end
