# frozen_string_literal: true

class CreateStatusPagePublishedIncidents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      create_table :status_page_published_incidents do |t|
        t.timestamps_with_timezone null: false
        t.references :issue, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      end
    end
  end

  def down
    drop_table :status_page_published_incidents
  end
end
