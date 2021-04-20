# frozen_string_literal: true

module Resolvers
  module Ci
    class JobsResolver < BaseResolver
      alias_method :pipeline, :object

      type ::Types::Ci::JobType.connection_type, null: true

      argument :security_report_types, [Types::Security::ReportTypeEnum],
              required: false,
              description: 'Filter jobs by the type of security report they produce.'

      argument :statuses, [::Types::Ci::JobStatusEnum],
              required: false,
              description: 'Filter jobs by status.'

      def resolve(statuses: nil, security_report_types: [])
        jobs = init_collection(security_report_types)
        jobs = jobs.with_status(statuses) if statuses.present?

        jobs
      end

      def init_collection(security_report_types)
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
