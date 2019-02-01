# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class PopulateMrMetricsWithEventsData < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 10_000
  MIGRATION = 'PopulateMergeRequestMetricsWithEventsDataImproved'
  PREVIOUS_MIGRATION = 'PopulateMergeRequestMetricsWithEventsData'

  disable_ddl_transaction!

  def up
    # Perform any ongoing background migration that might still be running from
    # previous try (see https://gitlab.com/gitlab-org/gitlab-ce/issues/47676).
    Gitlab::BackgroundMigration.steal(PREVIOUS_MIGRATION)

    say 'Scheduling `PopulateMergeRequestMetricsWithEventsData` jobs'
    # It will update around 4_000_000 records in batches of 10_000 merge
    # requests (running between 5 minutes) and should take around 53 hours to complete.
    # Apparently, production PostgreSQL is able to vacuum 10k-20k dead_tuples
    # per minute. So this should give us enough space.
    #
    # More information about the updates in `PopulateMergeRequestMetricsWithEventsDataImproved` class.
    #
    MergeRequest.all.each_batch(of: BATCH_SIZE) do |relation, index|
      range = relation.pluck('MIN(id)', 'MAX(id)').first

      BackgroundMigrationWorker.perform_in(index * 8.minutes, MIGRATION, range)
    end
  end

  def down
  end
end
