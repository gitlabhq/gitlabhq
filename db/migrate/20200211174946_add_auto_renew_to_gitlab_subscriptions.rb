# frozen_string_literal: true

class AddAutoRenewToGitlabSubscriptions < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :gitlab_subscription_histories, :auto_renew, :boolean
    add_column :gitlab_subscriptions, :auto_renew, :boolean
  end
end
