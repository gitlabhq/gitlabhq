class CreateCustomEmoji < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :custom_emoji do |t|
      t.references :namespace, index: true, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.string :file, null: false
      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false
    end
  end
end
