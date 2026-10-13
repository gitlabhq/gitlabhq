# frozen_string_literal: true

class CreateNamespaceOrganizations < ClickHouse::Migration
  # Maps a root namespace to its organization so the traversal_path rebuild can turn a legacy
  # `{root_ns}/.../{leaf}/` path into the org-scoped `{org_id}/{root_ns}/.../{leaf}/` form. The two
  # formats differ only by that leading component, and the root namespace id is the first component
  # of the legacy path, so this is all the rebuild needs.
  #
  # Populated from Postgres by ClickHouse::NamespaceOrganizationsSyncCronWorker rather than Siphon:
  # nothing built on ai_usage_events may depend on Siphon.
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/608216
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS namespace_organizations
      (
        root_namespace_id UInt64,
        organization_id UInt64,
        version DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC')
      )
      ENGINE = ReplacingMergeTree(version)
      ORDER BY root_namespace_id
      SETTINGS index_granularity = 8192
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS namespace_organizations
    SQL
  end
end
