class MigrateSubscriptionsProjectId < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = 'Subscriptions will not work as expected until this migration is complete.'

  def up
    execute <<-EOF.strip_heredoc
      UPDATE subscriptions
      SET project_id = (
        SELECT issues.project_id
        FROM issues
        WHERE issues.id = subscriptions.subscribable_id
      )
      WHERE subscriptions.subscribable_type = 'Issue';
    EOF

    execute <<-EOF.strip_heredoc
      UPDATE subscriptions
      SET project_id = (
        SELECT merge_requests.target_project_id
        FROM merge_requests
        WHERE merge_requests.id = subscriptions.subscribable_id
      )
      WHERE subscriptions.subscribable_type = 'MergeRequest';
    EOF

    execute <<-EOF.strip_heredoc
      UPDATE subscriptions
      SET project_id = (
        SELECT projects.id
        FROM labels INNER JOIN projects ON projects.id = labels.project_id
        WHERE labels.id = subscriptions.subscribable_id
      )
      WHERE subscriptions.subscribable_type = 'Label';
    EOF
  end

  def down
    execute <<-EOF.strip_heredoc
      UPDATE subscriptions SET project_id = NULL;
    EOF
  end
end
