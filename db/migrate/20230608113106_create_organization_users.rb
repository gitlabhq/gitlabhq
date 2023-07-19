# frozen_string_literal: true

class CreateOrganizationUsers < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    create_table :organization_users do |t|
      t.bigint :organization_id,
        null: false
      t.bigint :user_id,
        null: false,
        index: true
      t.timestamps_with_timezone null: false
      t.index 'organization_id, user_id',
        name: 'index_organization_users_on_organization_id_and_user_id', unique: true
    end
  end

  def down
    drop_table :organization_users
  end
end
