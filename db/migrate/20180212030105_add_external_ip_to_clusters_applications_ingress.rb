class AddExternalIpToClustersApplicationsIngress < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :clusters_applications_ingress, :external_ip, :string # rubocop:disable Migration/AddLimitToStringColumns
  end
end
