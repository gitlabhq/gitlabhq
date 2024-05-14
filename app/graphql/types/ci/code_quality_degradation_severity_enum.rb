# frozen_string_literal: true

module Types
  module Ci
    class CodeQualityDegradationSeverityEnum < BaseEnum
      graphql_name 'CodeQualityDegradationSeverity'

      ::Gitlab::Ci::Reports::CodequalityReports::SEVERITY_PRIORITIES.keys.each do |status|
        value status.upcase,
          description: "Code Quality degradation has a status of #{status}.",
          value: status
      end
    end
  end
end
