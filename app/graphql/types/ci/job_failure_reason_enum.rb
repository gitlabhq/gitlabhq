# frozen_string_literal: true

module Types
  module Ci
    class JobFailureReasonEnum < BaseEnum
      graphql_name 'CiJobFailureReason'

      ::Enums::Ci::CommitStatus.failure_reasons.each_key do |reason|
        value reason.to_s.upcase,
          description: "A job that failed due to #{reason.to_s.tr('_', ' ')}.",
          value: reason
      end
    end
  end
end
