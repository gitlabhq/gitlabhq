# frozen_string_literal: true

module Types
  module Notes
    # rubocop: disable Graphql/AuthorizeTypes
    # This is presented through `NoteType` that has its own authorization
    class DiffPositionType < BaseObject
      graphql_name 'DiffPosition'

      field :diff_refs,
        Types::DiffRefsType,
        null: false,
        description: 'Information about the branch, HEAD, and base at the time of commenting.'

      field :file_path, GraphQL::Types::String, null: false,
        description: 'Path of the file that was changed.'
      field :new_path, GraphQL::Types::String, null: true,
        description: 'Path of the file on the HEAD SHA.'
      field :old_path, GraphQL::Types::String, null: true,
        description: 'Path of the file on the start SHA.'
      field :position_type, Types::Notes::PositionTypeEnum, null: false,
        description: 'Type of file the position refers to.'

      # Fields for text positions
      field :new_line, GraphQL::Types::Int, null: true,
        description: 'Line on HEAD SHA that was changed.'
      field :old_line, GraphQL::Types::Int, null: true,
        description: 'Line on start SHA that was changed.'

      # Fields for image positions
      field :height, GraphQL::Types::Int, null: true,
        description: 'Total height of the image.'
      field :width, GraphQL::Types::Int, null: true,
        description: 'Total width of the image.'
      field :x, GraphQL::Types::Int, null: true,
        description: 'X position of the note.'
      field :y, GraphQL::Types::Int, null: true,
        description: 'Y position of the note.'

      def old_line
        object.old_line if object.on_text?
      end

      def new_line
        object.new_line if object.on_text?
      end

      def x
        object.x if object.on_image?
      end

      def y
        object.y if object.on_image?
      end

      def width
        object.width if object.on_image?
      end

      def height
        object.height if object.on_image?
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
