# frozen_string_literal: true

module Types
  module BaseInterface
    include GraphQL::Schema::Interface

    field_class ::Types::BaseField

    definition_methods do
      def authorized?(object, context)
        resolve_type(object, context).authorized?(object, context)
      end
    end
  end
end
