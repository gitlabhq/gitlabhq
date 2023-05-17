# frozen_string_literal: true

class RescheduleMigrationForLinks < Gitlab::Database::Migration[2.1]
  MIGRATION = 'MigrateLinksForVulnerabilityFindings'
  DELAY_INTERVAL = 2.minutes
  SUB_BATCH_SIZE = 500
  BATCH_SIZE = 10000

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # no-op as it is rescheduled via db/post_migrate/20230412141541_reschedule_links_avoiding_duplication.rb
  end

  def down
    # no-op as it is rescheduled via db/post_migrate/20230412141541_reschedule_links_avoiding_duplication.rb
  end
end
