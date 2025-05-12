# frozen_string_literal: true

class AddArchivedColumnToAnalyzerProjectStatuses < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    add_column :analyzer_project_statuses, :archived, :boolean, null: false, default: false
  end
end
