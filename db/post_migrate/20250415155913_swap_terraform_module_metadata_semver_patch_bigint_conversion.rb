# frozen_string_literal: true

class SwapTerraformModuleMetadataSemverPatchBigintConversion < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::Swapping

  disable_ddl_transaction!
  milestone '18.0'

  TABLE_NAME = :packages_terraform_module_metadata
  COLUMN_NAME = :semver_patch
  BIGINT_COLUMN_NAME = :semver_patch_convert_to_bigint
  TRIGGER_NAME = :trigger_dd7cb7bd6c9e

  def up
    swap
  end

  def down
    swap
  end

  private

  def swap
    with_lock_retries(raise_on_exhaustion: true) do
      lock_tables(TABLE_NAME)
      swap_columns(TABLE_NAME, COLUMN_NAME, BIGINT_COLUMN_NAME)
      reset_trigger_function(TRIGGER_NAME)
    end
  end
end
