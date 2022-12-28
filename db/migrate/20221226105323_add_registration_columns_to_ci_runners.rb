# frozen_string_literal: true

class AddRegistrationColumnsToCiRunners < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :ci_runners, :registration_type, :integer, limit: 1, default: 0, null: false
    add_column :ci_runners, :creator_id, :bigint, null: true
  end
end
