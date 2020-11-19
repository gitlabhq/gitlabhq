# frozen_string_literal: true

module Resolvers
  module Ci
    class JobsResolver < BaseResolver
      alias_method :pipeline, :object

      argument :security_report_types, [Types::Security::ReportTypeEnum],
              required: false,
              description: 'Filter jobs by the type of security report they produce'

      def resolve(security_report_types: [])
        if security_report_types.present?
          ::Security::SecurityJobsFinder.new(
            pipeline: pipeline,
            job_types: security_report_types
          ).execute
        else
          pipeline.statuses
        end
      end
    end
  end
end
