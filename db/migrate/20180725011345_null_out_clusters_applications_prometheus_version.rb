# frozen_string_literal: true

class NullOutClustersApplicationsPrometheusVersion < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    update_column_in_batches(:clusters_applications_prometheus, :version, nil) do |table, query|
      query.where(table[:version].not_eq('6.7.3'))
    end
  end

  def down
    # we cannot know the previous value for sure
  end
end
