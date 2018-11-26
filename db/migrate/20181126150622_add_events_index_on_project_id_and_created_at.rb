# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddEventsIndexOnProjectIdAndCreatedAt < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(*index_arguments)
  end

  def down
    remove_concurrent_index(*index_arguments)
  end

  private

  def index_arguments
    [
      :events,
      [:project_id, :created_at],
      {
        name: 'index_events_on_project_id_and_created_at'
      }
    ]
  end
end
