# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveInvalidJiraData < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    sql = "DELETE FROM jira_tracker_data WHERE \
        (length(encrypted_api_url) > 0 AND encrypted_api_url_iv IS NULL) \
        OR (length(encrypted_url) > 0 AND encrypted_url_iv IS NULL) \
        OR (length(encrypted_username) > 0 AND encrypted_username_iv IS NULL) \
        OR (length(encrypted_password) > 0 AND encrypted_password_iv IS NULL)"

    execute(sql)
  end

  def down
    # We need to figure out why migrating data to jira_tracker_data table
    # failed and then can recreate the data
  end
end
