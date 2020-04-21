class AddIpAddressToRunner < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_runners, :ip_address, :string # rubocop:disable Migration/PreventStrings
  end
end
