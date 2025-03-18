# frozen_string_literal: true

class AddProjectIdToProjectRelationExportUploads < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    add_column :project_relation_export_uploads, :project_id, :bigint
  end
end
