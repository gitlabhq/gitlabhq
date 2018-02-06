# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class DropEventsForMigrationTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class Event < ActiveRecord::Base
    include EachBatch
  end

  def up
    transaction do
      drop_table :events_for_migration
    end
  end

  # rubocop: disable Migration/Datetime
  def down
    create_table :events_for_migration do |t|
      t.string :target_type, index: true
      t.integer :target_id, index: true
      t.string :title
      t.text :data
      t.integer :project_id
      t.datetime :created_at, index: true
      t.datetime :updated_at
      t.integer :action, index: true
      t.integer :author_id, index: true

      t.index [:project_id, :id]
    end

    Event.all.each_batch do |relation|
      start_id, stop_id = relation.pluck('MIN(id), MAX(id)').first

      execute <<-EOF.strip_heredoc
      INSERT INTO events_for_migration (target_type, target_id, project_id, created_at, updated_at, action, author_id)
      SELECT target_type, target_id, project_id, created_at, updated_at, action, author_id
      FROM events
      WHERE id BETWEEN #{start_id} AND #{stop_id}
      EOF
    end
  end
end
