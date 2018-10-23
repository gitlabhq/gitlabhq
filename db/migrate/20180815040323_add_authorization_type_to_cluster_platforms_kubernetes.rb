# frozen_string_literal: true

class AddAuthorizationTypeToClusterPlatformsKubernetes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :cluster_platforms_kubernetes, :authorization_type, :integer, limit: 2
  end
end
