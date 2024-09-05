# frozen_string_literal: true

class AddPolicyActionLimitApplicationSetting < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  enable_lock_retries!

  def change
    add_column :application_settings, :security_policies, :jsonb, default: {}, null: false
  end
end
