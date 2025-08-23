# frozen_string_literal: true

module Types
  module Security
    class ReportTypeEnum < BaseEnum
      graphql_name 'SecurityReportTypeEnum'

      Enums::Security.analyzer_types.each_key do |report_type|
        value report_type.upcase,
          value: report_type,
          description: "#{report_type.upcase.to_s.tr('_', ' ')} scan report"
      end
    end
  end
end
