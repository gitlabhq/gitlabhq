# frozen_string_literal: true

class NullifyClustersApplications < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    change_column_null :clusters_applications_ingress, :version, true
    change_column_null :clusters_applications_jupyter, :version, true
    change_column_null :clusters_applications_prometheus, :version, true
    change_column_null :clusters_applications_runners, :version, true
  end
end
