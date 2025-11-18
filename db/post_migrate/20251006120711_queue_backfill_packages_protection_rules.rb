# frozen_string_literal: true

class QueueBackfillPackagesProtectionRules < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'BackfillPackagesProtectionRules'

  def up
    queue_batched_background_migration(
      MIGRATION,
      :packages_protection_rules,
      :id
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :packages_protection_rules, :id, [])
  end
end
