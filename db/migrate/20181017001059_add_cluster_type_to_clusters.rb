# frozen_string_literal: true

class AddClusterTypeToClusters < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :clusters, :cluster_type, :smallint
  end
end
