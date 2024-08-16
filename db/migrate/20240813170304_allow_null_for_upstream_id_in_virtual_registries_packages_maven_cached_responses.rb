# frozen_string_literal: true

class AllowNullForUpstreamIdInVirtualRegistriesPackagesMavenCachedResponses < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '17.4'

  def change
    change_column_null :virtual_registries_packages_maven_cached_responses, :upstream_id, true
  end
end
