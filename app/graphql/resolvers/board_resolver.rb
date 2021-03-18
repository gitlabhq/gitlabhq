# frozen_string_literal: true

module Resolvers
  class BoardResolver < BaseResolver.single
    alias_method :parent, :object

    type Types::BoardType, null: true

    argument :id, ::Types::GlobalIDType[::Board],
             required: true,
             description: 'The board\'s ID.'

    def resolve(id: nil)
      return unless parent

      ::Boards::BoardsFinder.new(parent, context[:current_user], board_id: extract_board_id(id)).execute.first
    rescue ActiveRecord::RecordNotFound
      nil
    end

    private

    def extract_board_id(gid)
      GitlabSchema.parse_gid(gid, expected_type: ::Board).model_id
    end
  end
end
