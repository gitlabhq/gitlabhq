# frozen_string_literal: true

class AddCustomersDotJwtSigningKeyToApplicationSettings < ActiveRecord::Migration[6.1]
  DOWNTIME = false

  def change
    add_column :application_settings, :encrypted_customers_dot_jwt_signing_key, :binary
    add_column :application_settings, :encrypted_customers_dot_jwt_signing_key_iv, :binary
  end
end
