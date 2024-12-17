# frozen_string_literal: true

class RemoveVirtualRegistriesPackagesMavenCachedResponsesDownloadsCountColumn < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.7'

  TABLE_NAME = :virtual_registries_packages_maven_cached_responses

  def up
    remove_column TABLE_NAME, :downloads_count, if_exists: true
  end

  def down
    add_column TABLE_NAME, :downloads_count, :integer, null: false, default: 1, if_not_exists: true

    add_check_constraint(TABLE_NAME, 'downloads_count > 0', 'check_c2aad543bf')
  end
end
