# frozen_string_literal: true

class AddRelayStateAllowlistSamlProviders < Gitlab::Database::Migration[2.1]
  def change
    add_column :saml_providers, :relay_state_domain_allowlist,
      :text,
      array: true,
      default: [],
      null: false
  end
end
