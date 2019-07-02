# frozen_string_literal: true

module Types
  module Notes
    # rubocop: disable Graphql/AuthorizeTypes
    # This is presented through `NoteType` that has its own authorization
    class DiffPositionType < BaseObject
      graphql_name 'DiffPosition'

      field :head_sha, GraphQL::STRING_TYPE, null: false,
            description: "The sha of the head at the time the comment was made"
      field :base_sha,  GraphQL::STRING_TYPE, null: true,
            description: "The merge base of the branch the comment was made on"
      field :start_sha, GraphQL::STRING_TYPE, null: false,
            description: "The sha of the branch being compared against"

      field :file_path, GraphQL::STRING_TYPE, null: false,
            description: "The path of the file that was changed"
      field :old_path, GraphQL::STRING_TYPE, null: true,
            description: "The path of the file on the start sha."
      field :new_path, GraphQL::STRING_TYPE, null: true,
            description: "The path of the file on the head sha."
      field :position_type, Types::Notes::PositionTypeEnum, null: false

      # Fields for text positions
      field :old_line, GraphQL::INT_TYPE, null: true,
            description: "The line on start sha that was changed",
            resolve: -> (position, _args, _ctx) { position.old_line if position.on_text? }
      field :new_line, GraphQL::INT_TYPE, null: true,
            description: "The line on head sha that was changed",
            resolve: -> (position, _args, _ctx) { position.new_line if position.on_text? }

      # Fields for image positions
      field :x, GraphQL::INT_TYPE, null: true,
            description: "The X postion on which the comment was made",
            resolve: -> (position, _args, _ctx) { position.x if position.on_image? }
      field :y, GraphQL::INT_TYPE, null: true,
            description: "The Y position on which the comment was made",
            resolve: -> (position, _args, _ctx) { position.y if position.on_image? }
      field :width, GraphQL::INT_TYPE, null: true,
            description: "The total width of the image",
            resolve: -> (position, _args, _ctx) { position.width if position.on_image? }
      field :height, GraphQL::INT_TYPE, null: true,
            description: "The total height of the image",
            resolve: -> (position, _args, _ctx) { position.height if position.on_image? }
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
