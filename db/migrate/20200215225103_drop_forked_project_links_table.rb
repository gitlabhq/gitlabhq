# frozen_string_literal: true

# rubocop:disable Migration/Datetime

class DropForkedProjectLinksTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    # rubocop:disable Migration/DropTable
    drop_table "forked_project_links", id: :serial do |t|
      t.integer "forked_to_project_id", null: false
      t.integer "forked_from_project_id", null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.index ["forked_to_project_id"], name: "index_forked_project_links_on_forked_to_project_id", unique: true
    end
    # rubocop:enable Migration/DropTable
  end
end
