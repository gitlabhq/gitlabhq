# frozen_string_literal: true

module WorkItems
  module SharedFilterArguments
    extend ActiveSupport::Concern

    included do
      argument :author_username,
        GraphQL::Types::String,
        required: false,
        description: 'Filter work items by author username.',
        alpha: { milestone: '15.9' }
      argument :iids,
        [GraphQL::Types::String],
        required: false,
        description: 'List of IIDs of work items. For example, `["1", "2"]`.'
      argument :state,
        Types::IssuableStateEnum,
        required: false,
        description: 'Current state of the work item.',
        prepare: ->(state, _ctx) {
          return state unless state == 'locked'

          raise Gitlab::Graphql::Errors::ArgumentError, Types::IssuableStateEnum::INVALID_LOCKED_MESSAGE
        }
      argument :types,
        [Types::IssueTypeEnum],
        as: :issue_types,
        description: 'Filter work items by the given work item types.',
        required: false
    end
  end
end
