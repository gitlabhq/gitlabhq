class CreateCustomEmoji < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :custom_emoji do |t|
      t.references :namespace, index: true, null: false, foreign_key: { on_delete: :cascade }
      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false
      t.string :name, null: false, limit: 36
      t.string :file, null: false
    end
  end
end
