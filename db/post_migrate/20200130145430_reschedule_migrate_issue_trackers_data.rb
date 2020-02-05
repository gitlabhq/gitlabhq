# frozen_string_literal: true

class RescheduleMigrateIssueTrackersData < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INTERVAL = 3.minutes.to_i
  BATCH_SIZE = 5_000
  MIGRATION = 'MigrateIssueTrackersSensitiveData'

  disable_ddl_transaction!

  class Service < ActiveRecord::Base
    self.table_name = 'services'
    self.inheritance_column = :_type_disabled

    include ::EachBatch
  end

  def up
    relation = Service.where(category: 'issue_tracker').where("properties IS NOT NULL AND properties != '{}' AND properties != ''")
    queue_background_migration_jobs_by_range_at_intervals(relation,
                                                          MIGRATION,
                                                          INTERVAL,
                                                          batch_size: BATCH_SIZE)
  end

  def down
    remove_issue_tracker_data_sql = "DELETE FROM issue_tracker_data WHERE \
        (length(encrypted_issues_url) > 0 AND encrypted_issues_url_iv IS NULL) \
        OR (length(encrypted_new_issue_url) > 0 AND encrypted_new_issue_url_iv IS NULL) \
        OR (length(encrypted_project_url) > 0 AND encrypted_project_url_iv IS NULL)"

    execute(remove_issue_tracker_data_sql)

    remove_jira_tracker_data_sql = "DELETE FROM jira_tracker_data WHERE \
        (length(encrypted_api_url) > 0 AND encrypted_api_url_iv IS NULL) \
        OR (length(encrypted_url) > 0 AND encrypted_url_iv IS NULL) \
        OR (length(encrypted_username) > 0 AND encrypted_username_iv IS NULL) \
        OR (length(encrypted_password) > 0 AND encrypted_password_iv IS NULL)"

    execute(remove_jira_tracker_data_sql)
  end
end
