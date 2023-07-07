# frozen_string_literal: true

class AddRelayStateAllowlistApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :relay_state_domain_allowlist,
      :text,
      array: true,
      default: [],
      null: false
  end
end
