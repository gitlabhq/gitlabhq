class AddConfidentialIssuesEventsToServices < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :services, :confidential_issues_events, :boolean, default: true, allow_null: false
  end

  def down
    remove_column :services, :confidential_issues_events
  end
end
