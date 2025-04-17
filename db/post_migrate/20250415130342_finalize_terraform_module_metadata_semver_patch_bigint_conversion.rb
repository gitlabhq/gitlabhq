# frozen_string_literal: true

class FinalizeTerraformModuleMetadataSemverPatchBigintConversion < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '18.0'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_backfill_conversion_of_integer_to_bigint_is_finished(
      :packages_terraform_module_metadata,
      %i[semver_patch],
      primary_key: :package_id
    )
  end

  def down; end
end
