# frozen_string_literal: true

class AllowNullFileChecksumInXrayReports < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    change_column_null :xray_reports, :file_checksum, true
  end
end
