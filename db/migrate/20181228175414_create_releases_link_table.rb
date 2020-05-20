# frozen_string_literal: true

class CreateReleasesLinkTable < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :release_links, id: :bigserial do |t|
      t.references :release, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.string :url, null: false
      t.string :name, null: false
      t.timestamps_with_timezone null: false

      t.index [:release_id, :url], unique: true
      t.index [:release_id, :name], unique: true
    end
  end
  # rubocop:enable Migration/PreventStrings
end
