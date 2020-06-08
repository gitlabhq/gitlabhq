# frozen_string_literal: true

class ScheduleFixRubyObjectInAuditEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_audit_events_on_ruby_object_in_details'
  INTERVAL = 2.minutes.to_i
  BATCH_SIZE = 1_000
  MIGRATION = 'FixRubyObjectInAuditEvents'

  disable_ddl_transaction!

  class AuditEvent < ActiveRecord::Base
    self.table_name = 'audit_events'

    include ::EachBatch
  end

  def up
    return unless Gitlab.ee?

    # create temporary index for audit_events with ruby/object in details field, may take well over 1h
    add_concurrent_index(:audit_events, :id, where: "details ~~ '%ruby/object%'", name: INDEX_NAME)

    relation = AuditEvent.where("details ~~ '%ruby/object%'")

    queue_background_migration_jobs_by_range_at_intervals(
      relation,
      MIGRATION,
      INTERVAL,
      batch_size: BATCH_SIZE
    )
  end

  def down
    # temporary index is to be dropped in a different migration in an upcoming release
    # https://gitlab.com/gitlab-org/gitlab/issues/196842
    remove_concurrent_index_by_name(:audit_events, INDEX_NAME)
  end
end
