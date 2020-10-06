# frozen_string_literal: true

class AddForeignKeyFromWebauthnRegistrationsToUsers < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # disable_ddl_transaction!

  def up
    with_lock_retries do
      add_foreign_key :webauthn_registrations, :users, column: :user_id, on_delete: :cascade
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key :webauthn_registrations, column: :user_id
    end
  end
end
