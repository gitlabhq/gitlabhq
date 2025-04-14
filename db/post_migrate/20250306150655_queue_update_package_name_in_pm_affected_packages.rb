# frozen_string_literal: true

class QueueUpdatePackageNameInPmAffectedPackages < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  restrict_gitlab_migration gitlab_schema: :gitlab_pm

  def up
    execute <<~SQL
      UPDATE pm_affected_packages SET package_name = REGEXP_REPLACE(LOWER(package_name), '[-_.]+', '-')
      WHERE purl_type = 8
      AND package_name != REGEXP_REPLACE(LOWER(package_name), '[-_.]+', '-')
      AND NOT EXISTS (
        SELECT 1 FROM pm_affected_packages as target
        WHERE target.purl_type = pm_affected_packages.purl_type
        AND target.package_name = REGEXP_REPLACE(LOWER(pm_affected_packages.package_name), '[-_.]+', '-')
        AND target.pm_advisory_id = pm_affected_packages.pm_advisory_id
        AND target.distro_version = pm_affected_packages.distro_version
      )
    SQL
  end

  def down
    # No-op
  end
end
