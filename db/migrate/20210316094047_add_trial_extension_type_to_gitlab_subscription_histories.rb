# frozen_string_literal: true

class AddTrialExtensionTypeToGitlabSubscriptionHistories < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :gitlab_subscription_histories, :trial_extension_type, :smallint
  end
end
