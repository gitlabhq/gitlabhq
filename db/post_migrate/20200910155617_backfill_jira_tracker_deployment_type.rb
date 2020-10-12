# frozen_string_literal: true

class BackfillJiraTrackerDeploymentType < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  MIGRATION = 'BackfillJiraTrackerDeploymentType'
  BATCH_SIZE = 100
  BATCH_INTERVAL = 20.seconds

  class JiraTrackerData < ActiveRecord::Base
    self.table_name = 'jira_tracker_data'

    include ::EachBatch
  end

  # 78_627 JiraTrackerData records, 76_313 with deployment_type == 0
  def up
    JiraTrackerData.where(deployment_type: 0).each_batch(of: BATCH_SIZE) do |relation, index|
      jobs  = relation.pluck(:id).map { |id| [MIGRATION, [id]] }
      delay = index * BATCH_INTERVAL

      bulk_migrate_in(delay, jobs)
    end
  end

  def down
    # no-op
    # intentionally blank
  end
end
