# frozen_string_literal: true

module Resolvers
  module WorkItems
    class TypesResolver < BaseResolver
      include LooksAhead

      type ::Types::WorkItems::TypeType.connection_type, null: true

      argument :name, ::Types::IssueTypeEnum,
        description: 'Filter work item types by the given name.',
        required: false

      # This field should be removed soon
      # https://gitlab.com/gitlab-org/gitlab/-/issues/540763
      argument :list_all, ::GraphQL::Types::Boolean,
        description: 'Returns all work item types, regardless of enablement status.',
        required: false,
        experiment: { milestone: "18.1" }

      validates mutually_exclusive: [:name, :list_all]

      def resolve_with_lookahead(name: nil, list_all: false)
        context.scoped_set!(:resource_parent, object)

        ::WorkItems::TypesFinder
          .new(container: object)
          .execute(name: name, list_all: list_all)
          .then { |types| apply_lookahead(types) }
      end

      private

      def preloads
        {
          widget_definitions: :enabled_widget_definitions
        }
      end

      def nested_preloads
        {
          widget_definitions: {
            allowed_child_types: :allowed_child_types_by_name,
            allowed_parent_types: :allowed_parent_types_by_name
          }
        }
      end
    end
  end
end
