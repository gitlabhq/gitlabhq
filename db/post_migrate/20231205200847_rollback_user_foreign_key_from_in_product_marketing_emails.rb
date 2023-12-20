# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RollbackUserForeignKeyFromInProductMarketingEmails < Gitlab::Database::Migration[2.2]
  milestone '16.8'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :in_product_marketing_emails, :users, name: 'fk_35c9101b63'
    end
  end

  def down
    add_concurrent_foreign_key :in_product_marketing_emails, :users, column: :user_id, name: 'fk_35c9101b63',
      on_delete: :cascade
  end
end
