# frozen_string_literal: true

class AddContractOveragesAllowedToGitlabSubscriptionHistories < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def up
    add_column :gitlab_subscription_histories, :contract_overages_allowed, :boolean, if_not_exists: true
  end

  def down
    remove_column :gitlab_subscription_histories, :contract_overages_allowed, if_exists: true
  end
end
