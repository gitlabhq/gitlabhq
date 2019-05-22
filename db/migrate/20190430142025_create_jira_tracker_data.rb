# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateJiraTrackerData < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :jira_tracker_data do |t|
      t.references :service, foreign_key: { on_delete: :cascade }, type: :integer, index: true, null: false
      t.timestamps_with_timezone
      t.string :encrypted_url
      t.string :encrypted_url_iv
      t.string :encrypted_api_url
      t.string :encrypted_api_url_iv
      t.string :encrypted_username
      t.string :encrypted_username_iv
      t.string :encrypted_password
      t.string :encrypted_password_iv
      t.string :jira_issue_transition_id
    end
  end
end
