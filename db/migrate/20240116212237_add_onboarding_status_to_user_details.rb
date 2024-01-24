# frozen_string_literal: true

class AddOnboardingStatusToUserDetails < Gitlab::Database::Migration[2.2]
  milestone '16.9'
  enable_lock_retries!

  def change
    add_column :user_details, :onboarding_status, :jsonb, default: {}, null: false
  end
end
