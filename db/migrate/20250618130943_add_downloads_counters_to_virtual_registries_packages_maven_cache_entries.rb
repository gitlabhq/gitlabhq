# frozen_string_literal: true

class AddDownloadsCountersToVirtualRegistriesPackagesMavenCacheEntries < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  TABLE_NAME = :virtual_registries_packages_maven_cache_entries

  def change
    add_column TABLE_NAME, :downloads_count, :bigint, default: 0, null: false
    add_column TABLE_NAME, :downloaded_at, :datetime_with_timezone
  end
end
