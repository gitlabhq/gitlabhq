# frozen_string_literal: true

module Resolvers
  module WorkItems
    class UserPreferenceResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type ::Types::WorkItems::UserPreference, null: true

      authorize :read_namespace

      argument :namespace_path,
        GraphQL::Types::ID,
        required: true,
        description: 'Full path of the namespace the work item is created in.'

      argument :work_item_type_id,
        ::Types::GlobalIDType[::WorkItems::Type],
        required: false,
        description: 'Global ID of a work item type.'

      def resolve(namespace_path:, work_item_type_id: nil)
        namespace = ::Routable.find_by_full_path(namespace_path)
        namespace = namespace.project_namespace if namespace.is_a?(Project)
        authorize!(namespace)

        work_item_type_id = work_item_type_id&.model_id

        ::WorkItems::UserPreference.find_by_user_namespace_and_work_item_type_id(
          current_user,
          namespace,
          work_item_type_id
        )
      end
    end
  end
end
