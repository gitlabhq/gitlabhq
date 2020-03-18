# frozen_string_literal: true

class AddCommentActionsToServices < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  # rubocop:disable Migration/AddColumnWithDefault
  # rubocop:disable Migration/UpdateLargeTable
  def up
    add_column_with_default(:services, :comment_on_event_enabled, :boolean, default: true)
  end
  # rubocop:enable Migration/AddColumnWithDefault
  # rubocop:enable Migration/UpdateLargeTable

  def down
    remove_column(:services, :comment_on_event_enabled)
  end
end
