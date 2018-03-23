class AddExternalIpToClustersApplicationsIngress < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :clusters_applications_ingress, :external_ip, :string
  end
end
