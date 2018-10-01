# frozen_string_literal: true

class AddNamespaceToClusterProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column(:cluster_projects, :namespace, :string, null: true)
  end
end
