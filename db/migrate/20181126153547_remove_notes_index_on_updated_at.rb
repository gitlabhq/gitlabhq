# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveNotesIndexOnUpdatedAt < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index(*index_arguments)
  end

  def down
    add_concurrent_index(*index_arguments)
  end

  private

  def index_arguments
    [
      :notes,
      [:updated_at],
      {
        name: 'index_notes_on_updated_at'
      }
    ]
  end
end
