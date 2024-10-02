# frozen_string_literal: true

class DropTokenWithIvsTable < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  enable_lock_retries!

  TABLE_NAME = :token_with_ivs

  def up
    drop_table TABLE_NAME
  end

  def down
    return if table_exists?(TABLE_NAME)

    create_table TABLE_NAME do |t|
      t.binary :hashed_token, null: false
      t.binary :hashed_plaintext_token, null: false
      t.binary :iv, null: false

      t.index :hashed_token,
        name: 'index_token_with_ivs_on_hashed_token',
        unique: true,
        using: :btree
      t.index :hashed_plaintext_token,
        name: 'index_token_with_ivs_on_hashed_plaintext_token',
        unique: true,
        using: :btree
    end
  end
end
