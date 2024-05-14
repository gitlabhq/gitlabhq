# frozen_string_literal: true

class DropPromoteUltimateFeaturesAtColumn < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  enable_lock_retries!

  def change
    remove_column :onboarding_progresses, :promote_ultimate_features_at, :datetime_with_timezone
  end
end
