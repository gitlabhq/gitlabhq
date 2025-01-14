# frozen_string_literal:true

class AddPersonalAccessTokenLastUsedIpsTable < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'idx_pat_last_used_ips_on_pat_id'

  milestone '17.8'

  def up
    create_table :personal_access_token_last_used_ips do |t|
      t.references :personal_access_token,
        foreign_key: { on_delete: :cascade },
        index: { name: INDEX_NAME },
        null: false
      t.references :organization, foreign_key: { on_delete: :cascade }, null: false
      t.timestamps_with_timezone
      t.inet :ip_address
    end
  end

  def down
    drop_table :personal_access_token_last_used_ips
  end
end
