# frozen_string_literal: true

class AddVerificationRetryCountsToGeoNodeStatuses < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :geo_node_statuses, :repositories_retrying_verification_count, :integer
    add_column :geo_node_statuses, :wikis_retrying_verification_count, :integer
  end
end
