class AddIpAddressToRunner < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_runners, :ip_address, :string
  end
end
