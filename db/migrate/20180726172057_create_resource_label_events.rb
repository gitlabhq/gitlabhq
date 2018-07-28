class CreateResourceLabelEvents < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :resource_label_events, id: :bigserial do |t|
      t.integer :action, null: false
      t.references :issue, null: true, index: true, foreign_key: { on_delete: :cascade }
      t.references :merge_request, null: true, index: true, foreign_key: { on_delete: :cascade }
      t.references :epic, null: true, index: true, foreign_key: { on_delete: :cascade }
      t.references :label, index: true, foreign_key: { on_delete: :nullify }
      t.references :user, index: true, foreign_key: { on_delete: :nullify }
      t.datetime_with_timezone :created_at, null: false
    end
  end
end
