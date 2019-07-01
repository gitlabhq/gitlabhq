# frozen_string_literal: true

module Mutations
  module Notes
    module Create
      class DiffNote < Base
        graphql_name 'CreateDiffNote'

        argument :position,
                  Types::Notes::DiffPositionInputType,
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
          position[:position_type] = 'text'
          position.merge!(position[:paths].to_h)

          Gitlab::Diff::Position.new(position)
        end
      end
    end
  end
end
