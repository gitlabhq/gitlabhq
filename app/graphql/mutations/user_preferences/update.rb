# frozen_string_literal: true

module Mutations
  module UserPreferences
    class Update < BaseMutation
      graphql_name 'UserPreferencesUpdate'

      NON_NULLABLE_ARGS = [
        :use_web_ide_extension_marketplace,
        :visibility_pipeline_id_type
      ].freeze

      argument :issues_sort, Types::IssueSortEnum,
               required: false,
               description: 'Sort order for issue lists.'
      argument :use_web_ide_extension_marketplace, GraphQL::Types::Boolean,
               required: false,
               description: 'Whether Web IDE Extension Marketplace is enabled for the user.'
      argument :visibility_pipeline_id_type, Types::VisibilityPipelineIdTypeEnum,
               required: false,
               description: 'Determines whether the pipeline list shows ID or IID.'

      field :user_preferences,
            Types::UserPreferencesType,
            null: true,
            description: 'User preferences after mutation.'

      def resolve(**attributes)
        attributes.delete_if { |key, value| NON_NULLABLE_ARGS.include?(key) && value.nil? }
        user_preferences = current_user.user_preference
        user_preferences.update(attributes)

        {
          user_preferences: user_preferences.valid? ? user_preferences : nil,
          errors: errors_on_object(user_preferences)
        }
      end
    end
  end
end
