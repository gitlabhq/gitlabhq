# frozen_string_literal: true

class AddContractOveragesAllowedToGitlabSubscriptions < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def up
    add_column :gitlab_subscriptions, :contract_overages_allowed, :boolean, default: true, null: false,
      if_not_exists: true
  end

  def down
    remove_column :gitlab_subscriptions, :contract_overages_allowed, if_exists: true
  end
end
