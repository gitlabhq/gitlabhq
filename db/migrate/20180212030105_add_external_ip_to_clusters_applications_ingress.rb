class AddExternalIpToClustersApplicationsIngress < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    add_column :clusters_applications_ingress, :external_ip, :string
  end
  # rubocop:enable Migration/PreventStrings
end
