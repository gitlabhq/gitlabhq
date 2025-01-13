# frozen_string_literal: true

class AddCheckConstraintsToVirtualRegistriesPackagesMavenCacheEntries < Gitlab::Database::Migration[2.2]
  milestone '17.8'
  disable_ddl_transaction!

  TABLE_NAME = :virtual_registries_packages_maven_cache_entries

  def up
    constraint = check_constraint_name(TABLE_NAME.to_s, 'file_md5', 'max_length')
    add_check_constraint(TABLE_NAME, 'file_md5 IS NULL OR octet_length(file_md5) = 16', constraint)

    constraint = check_constraint_name(TABLE_NAME.to_s, 'file_sha1', 'max_length')
    add_check_constraint(TABLE_NAME, 'octet_length(file_sha1) = 20', constraint)
  end

  def down
    constraint = check_constraint_name(TABLE_NAME.to_s, 'file_md5', 'max_length')
    remove_check_constraint(TABLE_NAME, constraint)

    constraint = check_constraint_name(TABLE_NAME.to_s, 'file_sha1', 'max_length')
    remove_check_constraint(TABLE_NAME, constraint)
  end
end
