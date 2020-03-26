# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveInvalidIssueTrackerData < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    sql = "DELETE FROM issue_tracker_data WHERE \
        (length(encrypted_issues_url) > 0 AND encrypted_issues_url_iv IS NULL) \
        OR (length(encrypted_new_issue_url) > 0 AND encrypted_new_issue_url_iv IS NULL) \
        OR (length(encrypted_project_url) > 0 AND encrypted_project_url_iv IS NULL)"

    execute(sql)
  end

  def down
    # We need to figure out why migrating data to issue_tracker_data table
    # failed and then can recreate the data
  end
end
