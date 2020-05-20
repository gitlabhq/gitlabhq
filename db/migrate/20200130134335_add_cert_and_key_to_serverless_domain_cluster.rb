# frozen_string_literal: true

class AddCertAndKeyToServerlessDomainCluster < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  # rubocop:disable Migration/AddLimitToTextColumns
  def change
    add_column :serverless_domain_cluster, :encrypted_key, :text
    add_column :serverless_domain_cluster, :encrypted_key_iv, :string, limit: 255
    add_column :serverless_domain_cluster, :certificate, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
  # rubocop:enable Migration/PreventStrings
end
