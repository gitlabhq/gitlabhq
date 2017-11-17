# rubocop:disable Migration/UpdateLargeTable
class AddTwoFactorColumnsToUsers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:users, :require_two_factor_authentication_from_group, :boolean, default: false)
    add_column_with_default(:users, :two_factor_grace_period, :integer, default: 48)
  end

  def down
    remove_column(:users, :require_two_factor_authentication_from_group)
    remove_column(:users, :two_factor_grace_period)
  end
end
