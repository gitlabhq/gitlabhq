# frozen_string_literal: true

class UpdateReportTypeForExistingApprovalProjectRules < Gitlab::Database::Migration[1.0]
  def up
    # 1. We only want to consider when rule_type is set to :report_approver (i.e., 2):
    #     enum rule_type: {
    #       regular: 0,
    #       code_owner: 1, # currently unused
    #       report_approver: 2,
    #       any_approver: 3
    #     }
    # 2. Also we want to change only the folowing names and respective values:
    #     DEFAULT_NAME_FOR_LICENSE_REPORT = 'License-Check'
    #     DEFAULT_NAME_FOR_VULNERABILITY_REPORT = 'Vulnerability-Check'
    #     DEFAULT_NAME_FOR_COVERAGE = 'Coverage-Check'
    #     enum report_type: {
    #       vulnerability: 1,
    #       license_scanning: 2,
    #       code_coverage: 3
    #     }

    execute <<~SQL
      UPDATE approval_project_rules
      SET report_type = converted_values.report_type
      FROM
        ( values
          (1, 'Vulnerability-Check'),
          (2, 'License-Check'),
          (3, 'Coverage-Check')
        ) AS converted_values(report_type, name)
      WHERE approval_project_rules.name = converted_values.name
      AND approval_project_rules.rule_type = 2;
    SQL
  end

  def down
    # no-op
  end
end
