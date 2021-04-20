# frozen_string_literal: true

class AddUserForeignKeyToInProductMarketingEmails < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :in_product_marketing_emails, :users, column: :user_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :in_product_marketing_emails, column: :user_id
    end
  end
end
