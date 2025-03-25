# frozen_string_literal: true

class InitConversionOfSemverPatchColumnInPkgsTerraformModuleMetadataToBigint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  TABLE = :packages_terraform_module_metadata
  COLUMN = :semver_patch

  def up
    initialize_conversion_of_integer_to_bigint(TABLE, COLUMN)
  end

  def down
    revert_initialize_conversion_of_integer_to_bigint(TABLE, COLUMN)
  end
end
