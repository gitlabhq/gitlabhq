# frozen_string_literal: true

module Resolvers
  class BoardListIssuesResolver < BaseResolver
    include BoardItemFilterable

    argument :filters, Types::Boards::BoardIssueInputType,
      required: false,
      description: 'Filters applied when selecting issues in the board list.'

    type Types::IssueType, null: true

    alias_method :list, :object

    def resolve(**args)
      filters = item_filters(args[:filters])
      mutually_exclusive_milestone_args!(filters)

      filter_params = filters.merge(board_id: list.board.id, id: list.id)
      service = ::Boards::Issues::ListService.new(list.board.resource_parent, context[:current_user], filter_params)

      service.execute
    end

    # https://gitlab.com/gitlab-org/gitlab/-/issues/235681
    def self.complexity_multiplier(args)
      0.005
    end

    private

    def mutually_exclusive_milestone_args!(filters)
      if filters[:milestone_title] && filters[:milestone_wildcard_id]
        raise ::Gitlab::Graphql::Errors::ArgumentError, 'Incompatible arguments: milestoneTitle, milestoneWildcardId.'
      end
    end
  end
end
