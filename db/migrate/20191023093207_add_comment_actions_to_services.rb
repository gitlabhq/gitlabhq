# frozen_string_literal: true

class AddCommentActionsToServices < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:services, :comment_on_event_enabled, :boolean, default: true)
  end

  def down
    remove_column(:services, :comment_on_event_enabled)
  end
end
