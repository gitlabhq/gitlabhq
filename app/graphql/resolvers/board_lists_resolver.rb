# frozen_string_literal: true

module Resolvers
  class BoardListsResolver < BaseResolver
    include BoardIssueFilterable
    include Gitlab::Graphql::Authorize::AuthorizeResource

    type Types::BoardListType, null: true

    argument :id, Types::GlobalIDType[List],
             required: false,
             description: 'Find a list by its global ID'

    argument :issue_filters, Types::Boards::BoardIssueInputType,
             required: false,
             description: 'Filters applied when getting issue metadata in the board list'

    alias_method :board, :object

    def resolve(lookahead: nil, id: nil, issue_filters: {})
      authorize!(board)

      lists = board_lists(id)
      context.scoped_set!(:issue_filters, issue_filters(issue_filters))

      if load_preferences?(lookahead)
        List.preload_preferences_for_user(lists, context[:current_user])
      end

      offset_pagination(lists)
    end

    private

    def board_lists(id)
      service = ::Boards::Lists::ListService.new(
        board.resource_parent,
        context[:current_user],
        list_id: extract_list_id(id)
      )

      service.execute(board, create_default_lists: false)
    end

    def authorized_resource?(board)
      Ability.allowed?(context[:current_user], :read_list, board)
    end

    def load_preferences?(lookahead)
      lookahead&.selection(:edges)&.selection(:node)&.selects?(:collapsed)
    end

    def extract_list_id(gid)
      return unless gid.present?

      GitlabSchema.parse_gid(gid, expected_type: ::List).model_id
    end
  end
end
