# frozen_string_literal: true

class AddNotNullToCiSourcesPipelinesOnProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  def up
    add_not_null_constraint(:ci_sources_pipelines, :project_id, validate: false)
  end

  def down
    remove_not_null_constraint(:ci_sources_pipelines, :project_id)
  end
end
