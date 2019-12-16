# frozen_string_literal: true

module Types
  module Notes
    # rubocop: disable Graphql/AuthorizeTypes
    # This is presented through `NoteType` that has its own authorization
    class DiffPositionType < BaseObject
      graphql_name 'DiffPosition'

      field :diff_refs, Types::DiffRefsType, null: false,
            description: 'Information about the branch, HEAD, and base at the time of commenting'

      field :file_path, GraphQL::STRING_TYPE, null: false,
            description: 'Path of the file that was changed'
      field :old_path, GraphQL::STRING_TYPE, null: true,
            description: 'Path of the file on the start SHA'
      field :new_path, GraphQL::STRING_TYPE, null: true,
            description: 'Path of the file on the HEAD SHA'
      field :position_type, Types::Notes::PositionTypeEnum, null: false,
            description: 'Type of file the position refers to'

      # Fields for text positions
      field :old_line, GraphQL::INT_TYPE, null: true,
            description: 'Line on start SHA that was changed',
            resolve: -> (position, _args, _ctx) { position.old_line if position.on_text? }
      field :new_line, GraphQL::INT_TYPE, null: true,
            description: 'Line on HEAD SHA that was changed',
            resolve: -> (position, _args, _ctx) { position.new_line if position.on_text? }

      # Fields for image positions
      field :x, GraphQL::INT_TYPE, null: true,
            description: 'X position on which the comment was made',
            resolve: -> (position, _args, _ctx) { position.x if position.on_image? }
      field :y, GraphQL::INT_TYPE, null: true,
            description: 'Y position on which the comment was made',
            resolve: -> (position, _args, _ctx) { position.y if position.on_image? }
      field :width, GraphQL::INT_TYPE, null: true,
            description: 'Total width of the image',
            resolve: -> (position, _args, _ctx) { position.width if position.on_image? }
      field :height, GraphQL::INT_TYPE, null: true,
            description: 'Total height of the image',
            resolve: -> (position, _args, _ctx) { position.height if position.on_image? }
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
