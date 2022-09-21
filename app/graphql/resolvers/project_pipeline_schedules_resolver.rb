# frozen_string_literal: true

module Resolvers
  class ProjectPipelineSchedulesResolver < BaseResolver
    alias_method :project, :object

    type ::Types::Ci::PipelineScheduleType.connection_type, null: true

    argument :status, ::Types::Ci::PipelineScheduleStatusEnum,
             required: false,
             description: 'Filter pipeline schedules by active status.'

    def resolve(status: nil)
      ::Ci::PipelineSchedulesFinder.new(project).execute(scope: status)
    end
  end
end
