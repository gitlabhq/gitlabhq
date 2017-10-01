class CreateCustomEmoji < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :custom_emoji do |t|
      t.references :namespace, index: true, foreign_key: { on_delete: :cascade }
      t.string :name, nil: false
      t.string :file, nil: false
      t.datetime_with_timezone :created_at
      t.datetime_with_timezone :updated_at
    end
  end
end

