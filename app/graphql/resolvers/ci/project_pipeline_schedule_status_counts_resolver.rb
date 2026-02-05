# frozen_string_literal: true

module Resolvers
  module Ci
    class ProjectPipelineScheduleStatusCountsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      alias_method :project, :object

      type ::Types::Ci::PipelineScheduleStatusCountType, null: true

      authorize :read_pipeline_schedule

      def resolve
        authorize!(project)

        schedules = project.pipeline_schedules

        counts = schedules.grouped_by_active
        {
          active: counts[true].to_i,
          inactive: counts[false].to_i,
          total: counts.values.sum
        }
      end
    end
  end
end
