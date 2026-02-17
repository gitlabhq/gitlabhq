# frozen_string_literal: true

class MakeUpstreamIdNullableOnVregPackagesMavenRegistryUpstreams < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  TABLE_NAME = :virtual_registries_packages_maven_registry_upstreams

  def up
    with_lock_retries do
      change_column_null TABLE_NAME, :upstream_id, true
    end
  end

  def down
    with_lock_retries do
      change_column_null TABLE_NAME, :upstream_id, false
    end
  end
end
