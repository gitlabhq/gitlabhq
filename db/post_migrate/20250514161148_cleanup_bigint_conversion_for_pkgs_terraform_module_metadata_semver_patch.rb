# frozen_string_literal: true

class CleanupBigintConversionForPkgsTerraformModuleMetadataSemverPatch < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  TABLE = :packages_terraform_module_metadata
  COLUMN = :semver_patch

  def up
    cleanup_conversion_of_integer_to_bigint(TABLE, COLUMN)
  end

  def down
    restore_conversion_of_integer_to_bigint(TABLE, COLUMN)
  end
end
