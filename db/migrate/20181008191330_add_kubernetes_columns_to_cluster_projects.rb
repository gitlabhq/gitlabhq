# frozen_string_literal: true

class AddKubernetesColumnsToClusterProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column(:cluster_projects, :namespace, :string)
    add_column(:cluster_projects, :service_account_name, :string)
    add_column(:cluster_projects, :encrypted_service_account_token, :text)
  end
end
