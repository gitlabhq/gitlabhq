# frozen_string_literal: true

class AddKnativeApplication < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    # rubocop:disable Migration/AddLimitToStringColumns
    create_table "clusters_applications_knative" do |t|
      t.references :cluster, null: false, unique: true, foreign_key: { on_delete: :cascade }

      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.integer "status", null: false
      t.string "version", null: false
      t.string "hostname"
      t.text "status_reason"
    end
    # rubocop:enable Migration/AddLimitToStringColumns
  end
end
