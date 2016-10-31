class MigrateSubscriptionsProjectId < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = 'Subscriptions will not work as expected until this migration is complete.'

  def up
    if Gitlab::Database.mysql?
      execute <<-EOF.strip_heredoc
        UPDATE subscriptions
          INNER JOIN issues ON issues.id = subscriptions.subscribable_id AND subscriptions.subscribable_type = 'Issue'
        SET subscriptions.project_id = issues.project_id;
      EOF

      execute <<-EOF.strip_heredoc
        UPDATE subscriptions
          INNER JOIN merge_requests ON merge_requests.id = subscriptions.subscribable_id AND subscriptions.subscribable_type = 'MergeRequest'
        SET subscriptions.project_id = merge_requests.target_project_id;
      EOF

      execute <<-EOF.strip_heredoc
        UPDATE subscriptions
          INNER JOIN labels ON labels.id = subscriptions.subscribable_id AND subscriptions.subscribable_type = 'Label'
          INNER JOIN projects ON projects.id = labels.project_id
        SET subscriptions.project_id = projects.id;
      EOF
    else
      execute <<-EOF.strip_heredoc
        UPDATE subscriptions
        SET project_id = issues.project_id
        FROM issues
        WHERE issues.id = subscriptions.subscribable_id
          AND subscriptions.subscribable_type = 'Issue';
      EOF

      execute <<-EOF.strip_heredoc
        UPDATE subscriptions
        SET project_id = merge_requests.target_project_id
        FROM merge_requests
        WHERE merge_requests.id = subscriptions.subscribable_id
          AND subscriptions.subscribable_type = 'MergeRequest';
      EOF

      execute <<-EOF.strip_heredoc
        UPDATE subscriptions
        SET project_id = projects.id
        FROM labels INNER JOIN projects ON projects.id = labels.project_id
        WHERE labels.id = subscriptions.subscribable_id
          AND subscriptions.subscribable_type = 'Label';
      EOF
    end
  end

  def down
    execute <<-EOF.strip_heredoc
      UPDATE subscriptions SET project_id = NULL;
    EOF
  end
end
