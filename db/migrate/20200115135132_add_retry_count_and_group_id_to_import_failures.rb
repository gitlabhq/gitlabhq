# frozen_string_literal: true

class AddRetryCountAndGroupIdToImportFailures < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :import_failures, :retry_count, :integer
    add_column :import_failures, :group_id, :integer
    change_column_null(:import_failures, :project_id, true)
  end
end
