# frozen_string_literal: true

class AddTextLimitToOnboardingStepUrl < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_text_limit :user_details, :onboarding_step_url, 2000
  end

  def down
    remove_text_limit :user_details, :onboarding_step_url
  end
end
