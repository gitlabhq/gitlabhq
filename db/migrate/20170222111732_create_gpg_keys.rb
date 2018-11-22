class CreateGpgKeys < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :gpg_keys do |t|
      t.timestamps_with_timezone null: false

      t.references :user, index: true, foreign_key: { on_delete: :cascade }

      t.binary :primary_keyid
      t.binary :fingerprint

      t.text :key

      t.index :primary_keyid, unique: true, length: mysql_compatible_index_length
      t.index :fingerprint, unique: true, length: mysql_compatible_index_length
    end
  end
end
