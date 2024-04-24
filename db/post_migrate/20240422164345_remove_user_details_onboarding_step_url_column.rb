# frozen_string_literal: true

class RemoveUserDetailsOnboardingStepUrlColumn < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  disable_ddl_transaction!

  def up
    remove_column :user_details, :onboarding_step_url, if_exists: true
  end

  def down
    add_column :user_details, :onboarding_step_url, :text, if_not_exists: true

    add_check_constraint(:user_details, 'char_length(onboarding_step_url) <= 2000', 'check_4f51129940')
  end
end
