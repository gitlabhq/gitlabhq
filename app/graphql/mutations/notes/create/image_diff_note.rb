# frozen_string_literal: true

module Mutations
  module Notes
    module Create
      class ImageDiffNote < Base
        graphql_name 'CreateImageDiffNote'

        argument :position,
          Types::Notes::DiffImagePositionInputType,
          required: true,
          description: copy_field_description(Types::Notes::NoteType, :position)

        private

        def create_note_params(noteable, args)
          super(noteable, args).merge({
            type: 'DiffNote',
            position: position(noteable, args)
          })
        end

        def position(noteable, args)
          position = args[:position].to_h
          position[:position_type] = 'image'
          position.merge!(position[:paths].to_h)

          Gitlab::Diff::Position.new(position)
        end
      end
    end
  end
end
