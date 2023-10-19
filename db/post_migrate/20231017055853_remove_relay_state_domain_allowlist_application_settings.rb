# frozen_string_literal: true

class RemoveRelayStateDomainAllowlistApplicationSettings < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    remove_column :application_settings, :relay_state_domain_allowlist
  end

  def down
    add_column :application_settings, :relay_state_domain_allowlist,
      :text,
      array: true,
      default: [],
      null: false
  end
end
