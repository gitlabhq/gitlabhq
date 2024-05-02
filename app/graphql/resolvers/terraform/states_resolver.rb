# frozen_string_literal: true

module Resolvers
  module Terraform
    class StatesResolver < BaseResolver
      type Types::Terraform::StateType.connection_type, null: true

      alias_method :project, :object

      when_single do
        argument :name, GraphQL::Types::String,
          required: true,
          description: 'Name of the Terraform state.'
      end

      def resolve(**args)
        ::Terraform::StatesFinder
          .new(project, current_user, params: args)
          .execute
      end
    end
  end
end
