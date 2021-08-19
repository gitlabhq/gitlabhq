# frozen_string_literal: true

module Mutations
  module Notes
    module Update
      class ImageDiffNote < Mutations::Notes::Update::Base
        graphql_name 'UpdateImageDiffNote'
        description <<~DESC
          Updates a DiffNote on an image (a `Note` where the `position.positionType` is `"image"`).
          #{QUICK_ACTION_ONLY_WARNING}
        DESC

        argument :body,
                 GraphQL::Types::String,
                 required: false,
                 description: copy_field_description(Types::Notes::NoteType, :body)

        argument :position,
                 Types::Notes::UpdateDiffImagePositionInputType,
                 required: false,
                 description: copy_field_description(Types::Notes::NoteType, :position)

        def ready?(**args)
          # As both arguments are optional, validate here that one of the
          # arguments are present.
          #
          # This may be able to be done using InputUnions in the future
          # if this RFC is merged:
          # https://github.com/graphql/graphql-spec/blob/master/rfcs/InputUnion.md
          if args.values_at(:body, :position).compact.blank?
            raise Gitlab::Graphql::Errors::ArgumentError,
                  'body or position arguments are required'
          end

          super(**args)
        end

        private

        def pre_update_checks!(note, _args)
          return if note.is_a?(DiffNote) && note.position.on_image?

          raise Gitlab::Graphql::Errors::ResourceNotAvailable, 'Resource is not an ImageDiffNote'
        end

        def note_params(note, args)
          super(note, args).merge(
            position: position_params(note, args)
          ).compact
        end

        def position_params(note, args)
          return unless args[:position]

          original_position = note.position.to_h

          Gitlab::Diff::Position.new(original_position.merge(args[:position]))
        end
      end
    end
  end
end
