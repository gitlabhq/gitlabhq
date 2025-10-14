# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddIndexAbuseReporToReporterId < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  disable_ddl_transaction!

  TABLE_NAME = :abuse_reports
  INDEX_NAME = 'index_abuse_reports_on_reporter_id'

  def up
    add_concurrent_index TABLE_NAME, :reporter_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
