# frozen_string_literal: true

module Types
  module Notes
    # InputType used for updateImageDiffNote mutation.
    class UpdateDiffImagePositionInputType < BaseInputObject
      graphql_name 'UpdateDiffImagePositionInput'

      argument :x, GraphQL::Types::Int,
        required: false,
        description: copy_field_description(Types::Notes::DiffPositionType, :x)

      argument :y, GraphQL::Types::Int,
        required: false,
        description: copy_field_description(Types::Notes::DiffPositionType, :y)

      argument :width, GraphQL::Types::Int,
        required: false,
        description: copy_field_description(Types::Notes::DiffPositionType, :width)

      argument :height, GraphQL::Types::Int,
        required: false,
        description: copy_field_description(Types::Notes::DiffPositionType, :height)

      def prepare
        to_h.compact.tap do |properties|
          if properties.empty?
            raise GraphQL::ExecutionError, "At least one property of `#{self.class.graphql_name}` must be set"
          end
        end

        super
      end
    end
  end
end
