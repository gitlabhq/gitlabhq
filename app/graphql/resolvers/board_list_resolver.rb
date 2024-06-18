# frozen_string_literal: true

module Resolvers
  class BoardListResolver < BaseResolver.single
    include Gitlab::Graphql::Authorize::AuthorizeResource
    include BoardItemFilterable

    type Types::BoardListType, null: true
    description 'Find an issue board list.'

    authorize :read_issue_board_list

    argument :id, Types::GlobalIDType[List],
      required: true,
      description: 'Global ID of the list.'

    argument :issue_filters, Types::Boards::BoardIssueInputType,
      required: false,
      description: 'Filters applied when getting issue metadata in the board list.'

    def resolve(id: nil, issue_filters: {})
      Gitlab::Graphql::Lazy.with_value(find_list(id: id)) do |list|
        context.scoped_set!(:issue_filters, item_filters(issue_filters))
        list if authorized_resource?(list)
      end
    end

    private

    def find_list(id:)
      GitlabSchema.object_from_id(id, expected_type: ::List)
    end
  end
end
