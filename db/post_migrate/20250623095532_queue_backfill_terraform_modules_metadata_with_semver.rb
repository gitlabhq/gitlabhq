# frozen_string_literal: true

class QueueBackfillTerraformModulesMetadataWithSemver < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'BackfillTerraformModulesMetadataWithSemver'

  # To be re-enqueued by:
  # db/post_migrate/20250708101955_requeue_backfill_terraform_modules_metadata_with_semver.rb
  def up
    # no-op
  end

  def down
    # no-op
  end
end
