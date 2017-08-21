class AddMinimumKeyLengthToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :application_settings, :minimum_rsa_bits, :integer, default: 1024
    add_column_with_default :application_settings, :minimum_dsa_bits, :integer, default: 1024
    add_column_with_default :application_settings, :minimum_ecdsa_bits, :integer, default: 256
    add_column_with_default :application_settings, :minimum_ed25519_bits, :integer, default: 256
    add_column_with_default :application_settings, :allowed_key_types, :string, default: %w[rsa dsa ecdsa ed25519].to_yaml
  end

  def down
    remove_column :application_settings, :minimum_rsa_bits
    remove_column :application_settings, :minimum_dsa_bits
    remove_column :application_settings, :minimum_ecdsa_bits
    remove_column :application_settings, :minimum_ed25519_bits
    remove_column :application_settings, :allowed_key_types
  end
end
