# frozen_string_literal: true

module Resolvers
  class ProjectPipelineSchedulesResolver < BaseResolver
    alias_method :project, :object

    type ::Types::Ci::PipelineScheduleType.connection_type, null: true

    argument :status, ::Types::Ci::PipelineScheduleStatusEnum,
             required: false,
             description: 'Filter pipeline schedules by active status.'

    argument :ids, [GraphQL::Types::ID],
             required: false,
             default_value: nil,
             description: 'Filter pipeline schedules by IDs.'

    def resolve(status: nil, ids: nil)
      ::Ci::PipelineSchedulesFinder.new(project).execute(scope: status, ids: ids)
    end
  end
end
