# frozen_string_literal: true

class AddEcdsaSkAndEd25519SkKeyRestrictionsToApplicationSettings < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    add_column :application_settings, :ecdsa_sk_key_restriction, :integer, default: 0, null: false
    add_column :application_settings, :ed25519_sk_key_restriction, :integer, default: 0, null: false
  end
end
