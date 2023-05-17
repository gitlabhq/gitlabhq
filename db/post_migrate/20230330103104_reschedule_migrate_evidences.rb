# frozen_string_literal: true

class RescheduleMigrateEvidences < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'MigrateEvidencesForVulnerabilityFindings'
  DELAY_INTERVAL = 2.minutes
  SUB_BATCH_SIZE = 500
  BATCH_SIZE = 10000

  def up
    # no-op as it has been rescheduled via db/post_migrate/20230508150219_reschedule_evidences_handling_unicode.rb
  end

  def down
    # no-op as it has been rescheduled via db/post_migrate/20230508150219_reschedule_evidences_handling_unicode.rb
  end
end
