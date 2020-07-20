# frozen_string_literal: true

class ValidateFileStoreNotNullConstraintOnLfsObjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    validate_check_constraint(:lfs_objects, :check_eecfc5717d)
  end

  def down
    # no-op
  end
end
