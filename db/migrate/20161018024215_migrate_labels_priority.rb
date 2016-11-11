class MigrateLabelsPriority < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = 'Prioritized labels will not work as expected until this migration is complete.'

  disable_ddl_transaction!

  def up
    execute <<-EOF.strip_heredoc
      INSERT INTO label_priorities (project_id, label_id, priority, created_at, updated_at)
      SELECT labels.project_id, labels.id, labels.priority, NOW(), NOW()
      FROM labels
      WHERE labels.project_id IS NOT NULL
        AND labels.priority IS NOT NULL;
    EOF
  end

  def down
    if Gitlab::Database.mysql?
      execute <<-EOF.strip_heredoc
        UPDATE labels
          INNER JOIN label_priorities ON labels.id = label_priorities.label_id AND labels.project_id = label_priorities.project_id
        SET labels.priority = label_priorities.priority;
      EOF
    else
      execute <<-EOF.strip_heredoc
        UPDATE labels
        SET priority = label_priorities.priority
        FROM label_priorities
        WHERE labels.id = label_priorities.label_id
          AND labels.project_id = label_priorities.project_id;
      EOF
    end
  end
end
