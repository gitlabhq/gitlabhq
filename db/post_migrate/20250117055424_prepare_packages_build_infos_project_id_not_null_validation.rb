# frozen_string_literal: true

class PreparePackagesBuildInfosProjectIdNotNullValidation < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  CONSTRAINT_NAME = :check_d979c653e1

  def up
    prepare_async_check_constraint_validation :packages_build_infos, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :packages_build_infos, name: CONSTRAINT_NAME
  end
end
