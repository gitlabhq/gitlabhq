class SetConfidentialIssuesEventsOnWebhooks < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    update_column_in_batches(:web_hooks, :confidential_issues_events, true) do |table, query|
      query.where(table[:issues_events].eq(true))
    end
  end

  def down
    # noop
  end
end
