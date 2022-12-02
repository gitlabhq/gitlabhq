# frozen_string_literal: true

class AddOnboardingStepUrlToUserDetails < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20221111123148_add_text_limit_to_onboarding_step_url.rb
  def up
    add_column :user_details, :onboarding_step_url, :text
  end

  def down
    remove_column :user_details, :onboarding_step_url
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
