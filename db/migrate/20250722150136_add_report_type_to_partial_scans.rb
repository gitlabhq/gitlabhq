# frozen_string_literal: true

class AddReportTypeToPartialScans < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    add_column :vulnerability_partial_scans, :scan_type, :smallint
  end
end
