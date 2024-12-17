# frozen_string_literal: true

class RemoveFileChecksumFromXrayReports < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def up
    remove_column :xray_reports, :file_checksum
  end

  def down
    add_column :xray_reports, :file_checksum, :binary, null: true
  end
end
