# frozen_string_literal: true

module Resolvers
  class BoardListIssuesResolver < BaseResolver
    type Types::IssueType, null: true

    alias_method :list, :object

    def resolve(**args)
      service = Boards::Issues::ListService.new(list.board.resource_parent, context[:current_user], { board_id: list.board.id, id: list.id })
      Gitlab::Graphql::Pagination::OffsetActiveRecordRelationConnection.new(service.execute)
    end

    # https://gitlab.com/gitlab-org/gitlab/-/issues/235681
    def self.complexity_multiplier(args)
      0.005
    end
  end
end
