# frozen_string_literal: true

class CreateCiSourcesProjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :ci_sources_projects do |t|
      t.bigint :pipeline_id, null: false
      t.bigint :source_project_id, null: false

      t.index [:source_project_id, :pipeline_id], unique: true
      t.index :pipeline_id
    end
  end
end
