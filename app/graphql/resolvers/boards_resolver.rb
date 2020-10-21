# frozen_string_literal: true

module Resolvers
  class BoardsResolver < BaseResolver
    type Types::BoardType, null: true

    argument :id, GraphQL::ID_TYPE,
             required: false,
             description: 'Find a board by its ID'

    def resolve(id: nil)
      # The project or group could have been loaded in batch by `BatchLoader`.
      # At this point we need the `id` of the project/group to query for boards, so
      # make sure it's loaded and not `nil` before continuing.
      parent = object.respond_to?(:sync) ? object.sync : object

      return Board.none unless parent

      ::Boards::ListService.new(parent, context[:current_user], board_id: extract_board_id(id)).execute(create_default_board: false)
    rescue ActiveRecord::RecordNotFound
      Board.none
    end

    private

    def extract_board_id(gid)
      return unless gid.present?

      GitlabSchema.parse_gid(gid, expected_type: ::Board).model_id
    end
  end
end
