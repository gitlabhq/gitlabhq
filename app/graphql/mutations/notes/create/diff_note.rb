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

        def ready?(**args)
          # As both arguments are optional, validate here that one of the
          # arguments are present.
          #
          # This may be able to be done using InputUnions in the future
          # if this RFC is merged:
          # https://github.com/graphql/graphql-spec/blob/master/rfcs/InputUnion.md

          if args[:position].to_hash.values_at(:old_line, :new_line).compact.blank?
            raise Gitlab::Graphql::Errors::ArgumentError,
              'position oldLine or newLine arguments are required'
          end

          super(**args)
        end

        private

        def create_note_params(noteable, args)
          super(noteable, args).merge({
            type: 'DiffNote',
            position: position(noteable, args),
            merge_request_diff_head_sha: args[:position][:head_sha]
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
