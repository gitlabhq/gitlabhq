class CreateCustomEmoji < ActiveRecord::Migration
  DOWNTIME = false

  def up
    create_table :custom_emoji do |t|
      t.references :namespace, index: true, foreign_key: { on_delete: :cascade }
      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false
      t.string :name, null: false
      t.string :file, null: false
    end
  end

  def down
    drop_table(:custom_emoji)
  end
end
