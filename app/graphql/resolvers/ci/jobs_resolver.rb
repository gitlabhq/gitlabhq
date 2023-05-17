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

      argument :retried, ::GraphQL::Types::Boolean,
              required: false,
              description: 'Filter jobs by retry-status.'

      argument :when_executed, [::GraphQL::Types::String],
              required: false,
              description: 'Filter jobs by when they are executed.'

      argument :job_kind, ::Types::Ci::JobKindEnum,
              required: false,
              description: 'Filter jobs by kind.'

      def resolve(statuses: nil, security_report_types: [], retried: nil, when_executed: nil, job_kind: nil)
        jobs = init_collection(security_report_types)
        jobs = jobs.with_status(statuses) if statuses.present?
        jobs = jobs.retried if retried
        jobs = jobs.with_when_executed(when_executed) if when_executed.present?
        jobs = jobs.latest if retried == false
        jobs = jobs.with_type(job_kind) if job_kind

        jobs
      end

      def init_collection(security_report_types)
        if security_report_types.present?
          ::Security::SecurityJobsFinder.new(
            pipeline: pipeline,
            job_types: security_report_types
          ).execute
        else
          pipeline.statuses_order_id_desc
        end
      end
    end
  end
end
