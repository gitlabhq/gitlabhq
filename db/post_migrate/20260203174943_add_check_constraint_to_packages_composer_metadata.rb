# frozen_string_literal: true

class AddCheckConstraintToPackagesComposerMetadata < Gitlab::Database::Migration[2.3]
  milestone '18.10'
  disable_ddl_transaction!

  TABLE_NAME = :packages_composer_metadata
  TARGET_SHA_CONSTRAINT_NAME = 'check_packages_composer_metadata_target_sha_max_length'
  VERSION_CACHE_SHA_CONSTRAINT_NAME = 'check_packages_composer_metadata_version_cache_sha_max_length'

  def up
    add_check_constraint(
      TABLE_NAME,
      'octet_length(target_sha) <= 64',
      TARGET_SHA_CONSTRAINT_NAME,
      validate: false
    )
    add_check_constraint(
      TABLE_NAME,
      'octet_length(version_cache_sha) <= 255',
      VERSION_CACHE_SHA_CONSTRAINT_NAME,
      validate: false
    )
  end

  def down
    remove_check_constraint(
      TABLE_NAME,
      TARGET_SHA_CONSTRAINT_NAME
    )
    remove_check_constraint(
      TABLE_NAME,
      VERSION_CACHE_SHA_CONSTRAINT_NAME
    )
  end
end
