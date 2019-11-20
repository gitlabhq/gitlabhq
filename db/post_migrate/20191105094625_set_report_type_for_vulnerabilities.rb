# frozen_string_literal: true

class SetReportTypeForVulnerabilities < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    # set report_type based on vulnerability_occurrences from which the vulnerabilities were promoted,
    # that is, first vulnerability_occurrences among those having the same vulnerability_id
    execute <<~SQL
    WITH first_findings_for_vulnerabilities AS (
      SELECT MIN(id) AS id, vulnerability_id
      FROM vulnerability_occurrences
      WHERE vulnerability_id IS NOT NULL
      GROUP BY vulnerability_id
    )
    UPDATE vulnerabilities
    SET report_type = vulnerability_occurrences.report_type
    FROM vulnerability_occurrences, first_findings_for_vulnerabilities
    WHERE vulnerability_occurrences.id = first_findings_for_vulnerabilities.id
    AND vulnerabilities.id = vulnerability_occurrences.vulnerability_id
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
