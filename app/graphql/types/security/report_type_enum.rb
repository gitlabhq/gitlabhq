# frozen_string_literal: true

module Types
  module Security
    class ReportTypeEnum < BaseEnum
      graphql_name 'SecurityReportTypeEnum'

      ::Security::SecurityJobsFinder.allowed_job_types.each do |report_type|
        value report_type.upcase,
          value: report_type,
          description: "#{report_type.upcase.to_s.tr('_', ' ')} scan report"
      end
    end
  end
end
