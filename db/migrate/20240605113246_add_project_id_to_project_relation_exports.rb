# frozen_string_literal: true

class AddProjectIdToProjectRelationExports < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :project_relation_exports, :project_id, :bigint
  end
end
