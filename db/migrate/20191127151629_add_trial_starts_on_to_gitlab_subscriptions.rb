# frozen_string_literal: true

class AddTrialStartsOnToGitlabSubscriptions < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :gitlab_subscriptions, :trial_starts_on, :date, null: true
    add_column :gitlab_subscription_histories, :trial_starts_on, :date, null: true
  end
end
