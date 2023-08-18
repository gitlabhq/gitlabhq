# frozen_string_literal: true

class AddPipelineIdAndExportTypeToDependencyListExports < Gitlab::Database::Migration[2.1]
  def change
    add_column :dependency_list_exports, :pipeline_id, :bigint
    add_column :dependency_list_exports, :export_type, :integer, limit: 2, default: 0, null: false
  end
end
