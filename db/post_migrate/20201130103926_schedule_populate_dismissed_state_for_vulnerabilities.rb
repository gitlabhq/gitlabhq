# frozen_string_literal: true

class SchedulePopulateDismissedStateForVulnerabilities < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  TMP_INDEX_NAME = 'tmp_index_on_vulnerabilities_non_dismissed'

  DOWNTIME = false
  BATCH_SIZE = 1_000
  VULNERABILITY_BATCH_SIZE = 5_000
  DELAY_INTERVAL = 3.minutes.to_i
  MIGRATION_CLASS = 'PopulateDismissedStateForVulnerabilities'

  VULNERABILITY_JOIN_CONDITION = 'JOIN "vulnerability_occurrences" ON "vulnerability_occurrences"."vulnerability_id" = "vulnerabilities"."id"'
  FEEDBACK_WHERE_CONDITION = <<~SQL
    EXISTS (SELECT 1 FROM vulnerability_feedback
      WHERE "vulnerability_occurrences"."project_id" = "vulnerability_feedback"."project_id"
      AND "vulnerability_occurrences"."report_type" = "vulnerability_feedback"."category"
      AND ENCODE("vulnerability_occurrences"."project_fingerprint", 'hex') = "vulnerability_feedback"."project_fingerprint"
      AND "vulnerability_feedback"."feedback_type" = 0
    )
  SQL

  class Vulnerability < ActiveRecord::Base # rubocop:disable Style/Documentation
    include EachBatch

    self.table_name = 'vulnerabilities'
  end

  disable_ddl_transaction!

  def up
    add_concurrent_index(:vulnerabilities, :id, where: 'state <> 2', name: TMP_INDEX_NAME)

    batch = []
    index = 1

    Vulnerability.where('state <> 2').each_batch(of: VULNERABILITY_BATCH_SIZE) do |relation|
      ids = relation
        .joins(VULNERABILITY_JOIN_CONDITION)
        .where(FEEDBACK_WHERE_CONDITION)
        .pluck('vulnerabilities.id')

      ids.each do |id|
        batch << id

        if batch.size == BATCH_SIZE
          migrate_in(index * DELAY_INTERVAL, MIGRATION_CLASS, batch)
          index += 1

          batch.clear
        end
      end
    end

    migrate_in(index * DELAY_INTERVAL, MIGRATION_CLASS, batch) unless batch.empty?
  end

  def down
    remove_concurrent_index_by_name(:vulnerabilities, TMP_INDEX_NAME)
  end
end
