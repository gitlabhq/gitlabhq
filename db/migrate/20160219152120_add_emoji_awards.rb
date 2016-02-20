class AddEmojiAwards < ActiveRecord::Migration
  def change
    create_table :emoji_awards do |t|
      t.string :name
      t.references :user
      t.references :awardable, polymorphic: true

      t.timestamps
    end

    add_index :emoji_awards, :user_id
    add_index :emoji_awards, :awardable_type
    add_index :emoji_awards, :awardable_id
  end
end
