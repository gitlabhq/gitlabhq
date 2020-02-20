# frozen_string_literal: true

module Resolvers
  class BoardsResolver < BaseResolver
    type Types::BoardType, null: true

    def resolve(**args)
      # The project or group could have been loaded in batch by `BatchLoader`.
      # At this point we need the `id` of the project/group to query for boards, so
      # make sure it's loaded and not `nil` before continuing.
      parent = object.respond_to?(:sync) ? object.sync : object

      return Board.none unless parent

      Boards::ListService.new(parent, context[:current_user]).execute(create_default_board: false)
    end
  end
end
