# frozen_string_literal: true

class CreateTokensWithIv < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :token_with_ivs do |t|
      t.binary :hashed_token, null: false
      t.binary :hashed_plaintext_token, null: false
      t.binary :iv, null: false

      t.index :hashed_token, name: 'index_token_with_ivs_on_hashed_token', unique: true, using: :btree
      t.index :hashed_plaintext_token, name: 'index_token_with_ivs_on_hashed_plaintext_token', unique: true, using: :btree
    end
  end
end
