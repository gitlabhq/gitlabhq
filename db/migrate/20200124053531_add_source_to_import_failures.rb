# frozen_string_literal: true

class AddSourceToImportFailures < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    add_column :import_failures, :source, :string, limit: 128
  end
  # rubocop:enable Migration/PreventStrings
end
