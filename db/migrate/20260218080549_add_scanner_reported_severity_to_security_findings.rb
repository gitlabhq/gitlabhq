# frozen_string_literal: true

class AddScannerReportedSeverityToSecurityFindings < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def change
    # rubocop:disable Migration/PreventAddingColumns -- Column needed to eliminate expensive LEFT JOIN in FindingsFinder
    add_column :security_findings, :scanner_reported_severity, :smallint
    # rubocop:enable Migration/PreventAddingColumns
  end
end
