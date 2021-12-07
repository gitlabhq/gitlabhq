# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveOldCalendarEventsIndex < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  OLD_INDEX_NAME = 'index_events_on_author_id_and_project_id'

  def up
    remove_concurrent_index_by_name :events, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :events, [:author_id, :project_id], name: OLD_INDEX_NAME
  end
end
