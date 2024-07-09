# frozen_string_literal: true

class AddUploadedByUserIdToUploads < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  enable_lock_retries!

  def change
    add_column :uploads, :uploaded_by_user_id, :bigint
  end
end
