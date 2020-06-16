# frozen_string_literal: true

class DropAnalyticsRepositoryFileEditsTable < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    # Requires ExclusiveLock on the table. Not in use, no records, no FKs.
    # rubocop:disable Migration/DropTable
    drop_table :analytics_repository_file_edits if table_exists?(:analytics_repository_file_edits) # this table might be already dropped on development environment
    # rubocop:enable Migration/DropTable
  end

  def down
    create_table :analytics_repository_file_edits do |t|
      t.bigint :project_id, null: false
      t.index :project_id
      t.bigint :analytics_repository_file_id, null: false
      t.date :committed_date, null: false
      t.integer :num_edits, null: false, default: 0
    end

    add_index :analytics_repository_file_edits,
      [:analytics_repository_file_id, :committed_date, :project_id],
      name: 'index_file_edits_on_committed_date_file_id_and_project_id',
      unique: true
  end
end
