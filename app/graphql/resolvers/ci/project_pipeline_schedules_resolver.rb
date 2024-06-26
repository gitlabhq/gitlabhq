# frozen_string_literal: true

module Resolvers
  module Ci
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

      argument :sort, ::Types::Ci::PipelineScheduleSortEnum,
        required: false, default_value: :id_desc,
        description: 'List pipeline schedules by sort order. Default is `id_desc`.'

      def resolve(status: nil, ids: nil, sort: :id_desc)
        ::Ci::PipelineSchedulesFinder.new(project, sort: sort).execute(scope: status, ids: ids)
      end
    end
  end
end
