# frozen_string_literal: true

module Mutations
  module WorkItems
    module UserPreference
      class Update < BaseMutation
        graphql_name 'WorkItemUserPreferenceUpdate'
        description "Create or Update user preferences for a work item type and namespace."

        include Mutations::SpamProtection
        include FindsNamespace

        authorize :read_namespace

        argument :namespace_path,
          type: GraphQL::Types::ID,
          required: true,
          description: 'Full path of the namespace on which the preference is set.'

        argument :work_item_type_id,
          type: ::Types::GlobalIDType[::WorkItems::Type],
          required: false,
          description: 'Global ID of a work item type.'

        argument :sort,
          type: ::Types::WorkItems::SortEnum,
          description: 'Sort order for work item lists.',
          required: false,
          default_value: :created_asc

        argument :display_settings,
          type: GraphQL::Types::JSON,
          description: 'Display settings for the work item lists.',
          required: false

        field :user_preferences,
          type: ::Types::WorkItems::UserPreference,
          description: 'User preferences.'

        def resolve(namespace_path:, work_item_type_id: nil, **attributes)
          namespace = find_object(namespace_path)
          namespace = namespace.project_namespace if namespace.is_a?(Project)
          authorize!(namespace)

          work_item_type_id = work_item_type_id&.model_id

          preferences = ::WorkItems::UserPreference.create_or_update(
            namespace: namespace,
            work_item_type_id: work_item_type_id,
            user: current_user,
            **attributes)

          {
            user_preferences: preferences.valid? ? preferences : nil,
            errors: errors_on_object(preferences)
          }
        end
      end
    end
  end
end
