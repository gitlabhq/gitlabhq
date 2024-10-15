# frozen_string_literal: true

class AllowTopLevelGroupOwnersToCreateServiceAccounts < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  enable_lock_retries!

  def change
    add_column :application_settings,
      :allow_top_level_group_owners_to_create_service_accounts,
      :boolean,
      default: false,
      null: false
  end
end
