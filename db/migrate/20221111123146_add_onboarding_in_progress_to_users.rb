# frozen_string_literal: true

class AddOnboardingInProgressToUsers < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  # rubocop:disable Migration/AddColumnsToWideTables
  def up
    add_column :users, :onboarding_in_progress, :boolean, default: false, null: false
  end

  def down
    remove_column :users, :onboarding_in_progress
  end
  # rubocop:enable Migration/AddColumnsToWideTables
end
