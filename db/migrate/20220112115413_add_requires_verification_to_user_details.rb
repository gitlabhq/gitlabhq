# frozen_string_literal: true

class AddRequiresVerificationToUserDetails < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    add_column :user_details, :requires_credit_card_verification, :boolean, null: false, default: false
  end
end
