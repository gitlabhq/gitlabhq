# frozen_string_literal: true

class AddIndexToZoomMeetings < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :zoom_meetings, :issue_status
  end

  def down
    remove_concurrent_index :zoom_meetings, :issue_status if index_exists?(:zoom_meetings, :issue_status)
  end
end
