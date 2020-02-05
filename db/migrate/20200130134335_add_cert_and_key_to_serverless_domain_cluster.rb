# frozen_string_literal: true

class AddCertAndKeyToServerlessDomainCluster < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :serverless_domain_cluster, :encrypted_key, :text
    add_column :serverless_domain_cluster, :encrypted_key_iv, :string, limit: 255
    add_column :serverless_domain_cluster, :certificate, :text
  end
end
