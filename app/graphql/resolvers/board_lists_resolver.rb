# frozen_string_literal: true

module Resolvers
  class BoardListsResolver < BaseResolver
    include BoardItemFilterable
    include Gitlab::Graphql::Authorize::AuthorizeResource
    include LooksAhead

    type Types::BoardListType, null: true
    authorize :read_issue_board_list
    authorizes_object!

    argument :id, Types::GlobalIDType[List],
      required: false,
      description: 'Find a list by its global ID.'

    argument :issue_filters, Types::Boards::BoardIssueInputType,
      required: false,
      description: 'Filters applied when getting issue metadata in the board list.'

    alias_method :board, :object

    def resolve_with_lookahead(id: nil, issue_filters: {})
      lists = board_lists(id)
      context.scoped_set!(:issue_filters, item_filters(issue_filters))

      List.preload_preferences_for_user(lists, current_user) if load_preferences?

      offset_pagination(lists)
    end

    private

    def board_lists(id)
      service = ::Boards::Lists::ListService.new(
        board.resource_parent,
        current_user,
        list_id: extract_list_id(id)
      )

      service.execute(board, create_default_lists: false)
    end

    def load_preferences?
      node_selection&.selects?(:collapsed)
    end

    def extract_list_id(gid)
      return unless gid.present?

      GitlabSchema.parse_gid(gid, expected_type: ::List).model_id
    end
  end
end
