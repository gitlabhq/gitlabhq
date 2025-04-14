# frozen_string_literal: true

class PreparePackagesNpmMetadataProjectIdNotNullValidation < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  CONSTRAINT_NAME = :check_8d2e047947

  def up
    prepare_async_check_constraint_validation :packages_npm_metadata, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :packages_npm_metadata, name: CONSTRAINT_NAME
  end
end
