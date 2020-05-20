# frozen_string_literal: true

class AddKnativeApplication < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table "clusters_applications_knative" do |t|
      t.references :cluster, null: false, unique: true, foreign_key: { on_delete: :cascade }

      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.integer "status", null: false
      t.string "version", null: false
      t.string "hostname"
      t.text "status_reason" # rubocop:disable Migration/AddLimitToTextColumns
    end
  end
  # rubocop:enable Migration/PreventStrings
end
