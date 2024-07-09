# frozen_string_literal: true

class AddFkToUploadedByUserIdOnUploads < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :uploads, :users, column: :uploaded_by_user_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key :uploads, column: :uploaded_by_user_id
    end
  end
end
