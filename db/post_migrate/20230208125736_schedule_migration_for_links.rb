# frozen_string_literal: true

class ScheduleMigrationForLinks < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'MigrateLinksForVulnerabilityFindings'
  DELAY_INTERVAL = 2.minutes
  SUB_BATCH_SIZE = 500
  BATCH_SIZE = 10000

  def up
    # no-op as it is rescheduled via db/post_migrate/20230314144640_reschedule_migration_for_links.rb
  end

  def down
    # no-op as it is rescheduled via db/post_migrate/20230314144640_reschedule_migration_for_links.rb
  end
end
