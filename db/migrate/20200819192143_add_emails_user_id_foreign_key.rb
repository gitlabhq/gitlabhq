# frozen_string_literal: true

class AddEmailsUserIdForeignKey < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  CONSTRAINT_NAME = 'fk_emails_user_id'

  def up
    with_lock_retries do
      add_foreign_key :emails, :users, on_delete: :cascade, validate: false, name: CONSTRAINT_NAME
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :emails, column: :user_id, name: CONSTRAINT_NAME
    end
  end
end
