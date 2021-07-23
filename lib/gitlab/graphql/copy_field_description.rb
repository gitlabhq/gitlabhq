# frozen_string_literal: true

module Gitlab
  module Graphql
    module CopyFieldDescription
      extend ActiveSupport::Concern

      class_methods do
        # Returns the `description` for property of field `field_name` on type.
        # This can be used to ensure, for example, that mutation argument descriptions
        # are always identical to the corresponding query field descriptions.
        #
        # E.g.:
        #   argument :name, GraphQL::Types::String, description: copy_field_description(Types::UserType, :name)
        def copy_field_description(type, field_name)
          type.fields[field_name.to_s.camelize(:lower)].description
        end
      end
    end
  end
end
