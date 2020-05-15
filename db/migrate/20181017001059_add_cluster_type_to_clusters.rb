# frozen_string_literal: true

class AddClusterTypeToClusters < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  PROJECT_CLUSTER_TYPE = 3

  disable_ddl_transaction!

  def up
    add_column_with_default(:clusters, :cluster_type, :smallint, default: PROJECT_CLUSTER_TYPE) # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column(:clusters, :cluster_type)
  end
end
