# frozen_string_literal: true

class CleanupRegistryUpstreamsWithNullUpstreamId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.9'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  class RegistryUpstream < MigrationRecord
    include EachBatch

    self.table_name = 'virtual_registries_packages_maven_registry_upstreams'
  end

  def up
    # no-op - required to allow rollback of MakeUpstreamIdNullableOnVregPackagesMavenRegistryUpstreams
  end

  def down
    RegistryUpstream.each_batch do |relation|
      relation.where(upstream_id: nil).delete_all
    end
  end
end
