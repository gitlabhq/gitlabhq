# frozen_string_literal: true

class BackfillPkgsTerraformModulesMetadataForSemverBigintConversion < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.11'

  TABLE = :packages_terraform_module_metadata
  COLUMN = :semver_patch

  def up
    backfill_conversion_of_integer_to_bigint(TABLE, COLUMN, primary_key: :package_id)
  end

  def down
    revert_backfill_conversion_of_integer_to_bigint(TABLE, COLUMN, primary_key: :package_id)
  end
end
