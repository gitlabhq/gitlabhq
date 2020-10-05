# frozen_string_literal: true

class AddPagesDeploymentIdToPagesMetadata < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :project_pages_metadata, :pages_deployment_id, :bigint
  end
end
