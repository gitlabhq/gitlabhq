# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authz
      # Finds GranularScope directives by checking field, owner, implementing type, and return type
      class DirectiveFinder
        include TypeUnwrapper

        def initialize(field)
          @field = field
        end

        def find(object)
          find_on_field ||
            find_on_owner ||
            find_on_implementing_type(object) ||
            find_on_return_type
        end

        private

        def find_on_field
          find_directive(@field)
        end

        def find_on_owner
          find_directive(@field.owner)
        end

        def find_on_implementing_type(object)
          return unless @field.owner&.kind&.interface? && object

          implementing_type = resolve_implementing_type(object)
          find_directive(implementing_type)
        end

        def find_on_return_type
          return_type = unwrap_type(@field.type)

          find_directive(return_type)
        end

        def resolve_implementing_type(object)
          # GraphQL wraps the model in a type object, get the actual model from object.object
          model = object.respond_to?(:object) ? object.object : object
          # Unwrap presenters (e.g., IssuePresenter wraps Issue)
          model = model.__getobj__ if model.respond_to?(:__getobj__)
          # Use model's class name to find the GraphQL type (e.g., Issue -> "Issue")
          GitlabSchema.types[model.class.name]
        end

        def find_directive(field_or_type)
          return unless field_or_type.respond_to?(:directives)

          field_or_type.directives.find { |d| d.is_a?(Directives::Authz::GranularScope) }
        end
      end
    end
  end
end
