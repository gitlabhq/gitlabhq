# frozen_string_literal: true

module Mutations
  module Ci
    module Runner
      module CommonMutationArguments
        extend ActiveSupport::Concern

        included do
          argument :description, GraphQL::Types::String,
            required: false,
            description: 'Description of the runner.'

          argument :maintenance_note, GraphQL::Types::String,
            required: false,
            description: 'Runner\'s maintenance notes.'

          argument :maximum_timeout, GraphQL::Types::Int,
            required: false,
            description: 'Maximum timeout (in seconds) for jobs processed by the runner.'

          argument :access_level, ::Types::Ci::RunnerAccessLevelEnum,
            required: false,
            description: 'Access level of the runner.'

          argument :paused, GraphQL::Types::Boolean,
            required: false,
            description: 'Indicates the runner is not allowed to receive jobs.'

          argument :locked, GraphQL::Types::Boolean,
            required: false,
            description: 'Indicates the runner is locked.'

          argument :run_untagged, GraphQL::Types::Boolean,
            required: false,
            description: 'Indicates the runner is able to run untagged jobs.'

          argument :tag_list, [GraphQL::Types::String],
            required: false,
            description: 'Tags associated with the runner.'
        end
      end
    end
  end
end
