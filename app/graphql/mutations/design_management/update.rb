# frozen_string_literal: true

module Mutations
  module DesignManagement
    class Update < ::Mutations::BaseMutation
      graphql_name "DesignManagementUpdate"

      authorize :update_design

      argument :id, ::Types::GlobalIDType[::DesignManagement::Design],
        required: true,
        description: "ID of the design to update."

      argument :description, GraphQL::Types::String,
        required: false,
        description: copy_field_description(Types::DesignManagement::DesignType, :description)

      field :design, Types::DesignManagement::DesignType,
        null: false,
        description: "Updated design."

      def resolve(id:, description:)
        design = authorized_find!(id: id)
        design.update(description: description)

        {
          design: design.reset,
          errors: errors_on_object(design)
        }
      end
    end
  end
end
