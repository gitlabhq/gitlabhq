# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateIssueTrackerData < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :issue_tracker_data do |t|
      t.references :service, foreign_key: { on_delete: :cascade }, type: :integer, index: true, null: false
      t.timestamps_with_timezone
      t.string :encrypted_project_url
      t.string :encrypted_project_url_iv
      t.string :encrypted_issues_url
      t.string :encrypted_issues_url_iv
      t.string :encrypted_new_issue_url
      t.string :encrypted_new_issue_url_iv
    end
  end
  # rubocop:enable Migration/PreventStrings
end
