# rubocop:disable Migration/UpdateLargeTable
class AddTwoFactorColumnsToNamespaces < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:namespaces, :require_two_factor_authentication, :boolean, default: false)
    add_column_with_default(:namespaces, :two_factor_grace_period, :integer, default: 48)

    add_concurrent_index(:namespaces, :require_two_factor_authentication)
  end

  def down
    remove_column(:namespaces, :require_two_factor_authentication)
    remove_column(:namespaces, :two_factor_grace_period)

    remove_concurrent_index(:namespaces, :require_two_factor_authentication) if index_exists?(:namespaces, :require_two_factor_authentication)
  end
end
