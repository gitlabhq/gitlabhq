class CreatePersonalAccessTokens < ActiveRecord::Migration
  def change
    create_table :personal_access_tokens do |t|
      t.references :user, index: true, foreign_key: true, null: false
      t.string :token, index: {unique: true}, null: false
      t.string :name, null: false

      t.timestamps null: false
    end
  end
end
