# frozen_string_literal: true

class SetReportTypeForVulnerabilities < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    # set report_type based on associated vulnerability_occurrences
    execute <<~SQL
    UPDATE vulnerabilities
    SET report_type = vulnerability_occurrences.report_type
    FROM vulnerability_occurrences
    WHERE vulnerabilities.id = vulnerability_occurrences.vulnerability_id
    SQL

    # set default report_type for orphan vulnerabilities (there should be none but...)
    execute 'UPDATE vulnerabilities SET report_type = 0 WHERE report_type IS NULL'

    change_column_null :vulnerabilities, :report_type, false
  end

  def down
    change_column_null :vulnerabilities, :report_type, true

    execute 'UPDATE vulnerabilities SET report_type = NULL'
  end
end
