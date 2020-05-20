# frozen_string_literal: true

class CreateZoomMeetings < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  ZOOM_MEETING_STATUS_ADDED = 1

  def change
    create_table :zoom_meetings do |t|
      t.references :project, foreign_key: { on_delete: :cascade },
        null: false
      t.references :issue, foreign_key: { on_delete: :cascade },
        null: false
      t.timestamps_with_timezone null: false
      t.integer :issue_status, limit: 2, default: 1, null: false
      t.string :url, limit: 255 # rubocop:disable Migration/PreventStrings

      t.index [:issue_id, :issue_status], unique: true,
        where: "issue_status = #{ZOOM_MEETING_STATUS_ADDED}"
    end
  end
end
