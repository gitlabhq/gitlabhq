# frozen_string_literal: true

class AddIssueCreatedAtToOnboardingProgress < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :onboarding_progresses, :issue_created_at, :datetime_with_timezone
  end
end
