# rubocop:disable all
class AddAwardEmoji < ActiveRecord::Migration
  def change
    create_table :award_emoji do |t|
      t.string :name
      t.references :user
      t.references :awardable, polymorphic: true

      t.timestamps
    end

    add_index :award_emoji, :user_id
    add_index :award_emoji, [:awardable_type, :awardable_id]
  end
end
