class CreateLabelPriorities < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = 'Prioritezed labels will not work as expected until this migration is complete.'

  disable_ddl_transaction!

  def up
    create_table :label_priorities do |t|
      t.references :project, foreign_key: { on_delete: :cascade }, null: false
      t.references :label, foreign_key: { on_delete: :cascade }, null: false
      t.integer :priority, null: false

      t.timestamps null: false
    end

    execute <<-EOF.strip_heredoc
      INSERT INTO label_priorities (project_id, label_id, priority, created_at, updated_at)
      SELECT labels.project_id, labels.id, labels.priority, NOW(), NOW()
      FROM labels
      WHERE labels.project_id IS NOT NULL
        AND labels.priority IS NOT NULL;
    EOF

    add_concurrent_index :label_priorities, [:project_id, :label_id], unique: true
    add_concurrent_index :label_priorities, :priority

    remove_column :labels, :priority
  end

  def down
    add_column :labels, :priority, :integer

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

    add_concurrent_index :labels, :priority

    drop_table :label_priorities
  end
end
